#!/bin/bash
# Upload a file to Google Drive using a service account
# Usage: ./upload-to-drive.sh <file_path> [drive_folder_id]
set -euo pipefail

FILE_PATH="${1:?Usage: upload-to-drive.sh <file_path> [drive_folder_id]}"
FOLDER_ID="${2:-$DRIVE_OUTPUT_FOLDER_ID}"
FILE_NAME=$(basename "$FILE_PATH")

if [ ! -f "$FILE_PATH" ]; then
  echo "::error::File not found: $FILE_PATH"
  exit 1
fi

# Write service account credentials to temp file
SA_KEY=$(mktemp)
trap 'rm -f "$SA_KEY"' EXIT
echo "$GOOGLE_SERVICE_ACCOUNT" > "$SA_KEY"

# Generate JWT for Google OAuth2
ACCESS_TOKEN=$(python3 - "$SA_KEY" <<'PYEOF'
import json, sys, time, base64, subprocess

key_file = sys.argv[1]
key = json.load(open(key_file))

def b64url(data):
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

header = b64url(json.dumps({"alg": "RS256", "typ": "JWT"}).encode())
now = int(time.time())
payload = b64url(json.dumps({
    "iss": key["client_email"],
    "scope": "https://www.googleapis.com/auth/drive.file",
    "aud": "https://oauth2.googleapis.com/token",
    "iat": now,
    "exp": now + 3600,
}).encode())

signing_input = f"{header}.{payload}".encode()

# Extract private key to a temp PEM file
import tempfile, os
pem = tempfile.NamedTemporaryFile(mode="w", suffix=".pem", delete=False)
pem.write(key["private_key"])
pem.close()

try:
    sig = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", pem.name],
        input=signing_input, capture_output=True, check=True,
    ).stdout
finally:
    os.unlink(pem.name)

jwt = f"{header}.{payload}.{b64url(sig)}"

import urllib.request, urllib.parse
resp = urllib.request.urlopen(urllib.request.Request(
    "https://oauth2.googleapis.com/token",
    data=urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": jwt,
    }).encode(),
))
print(json.loads(resp.read())["access_token"])
PYEOF
)

echo "Uploading $FILE_NAME to Drive folder $FOLDER_ID..."

RESPONSE=$(curl -s -X POST \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "metadata={\"name\": \"$FILE_NAME\", \"parents\": [\"$FOLDER_ID\"]};type=application/json;charset=UTF-8" \
  -F "file=@$FILE_PATH")

FILE_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")

if [ -z "$FILE_ID" ]; then
  echo "::error::Upload failed"
  echo "$RESPONSE"
  exit 1
fi

echo "Uploaded: $FILE_NAME (ID: $FILE_ID)"
echo "drive_file_id=$FILE_ID" >> "${GITHUB_OUTPUT:-/dev/null}"
