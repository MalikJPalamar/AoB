#!/bin/bash
# Download a file from Google Drive using a service account
# Usage: ./download-from-drive.sh <file_id> <output_path>
set -euo pipefail

FILE_ID="${1:?Usage: download-from-drive.sh <file_id> <output_path>}"
OUTPUT_PATH="${2:?Usage: download-from-drive.sh <file_id> <output_path>}"

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
    "scope": "https://www.googleapis.com/auth/drive.readonly",
    "aud": "https://oauth2.googleapis.com/token",
    "iat": now,
    "exp": now + 3600,
}).encode())

signing_input = f"{header}.{payload}".encode()

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

echo "Downloading file $FILE_ID to $OUTPUT_PATH..."

HTTP_CODE=$(curl -s -w "%{http_code}" -o "$OUTPUT_PATH" \
  "https://www.googleapis.com/drive/v3/files/${FILE_ID}?alt=media" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$HTTP_CODE" != "200" ]; then
  echo "::error::Download failed (HTTP $HTTP_CODE)"
  cat "$OUTPUT_PATH"
  exit 1
fi

echo "Downloaded: $OUTPUT_PATH ($(du -h "$OUTPUT_PATH" | cut -f1))"
