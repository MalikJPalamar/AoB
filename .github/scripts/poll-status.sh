#!/bin/bash
# Poll HeyGen video or translation status until complete
# Usage: ./poll-status.sh <type> <id> [timeout_minutes]
#   type: "video" or "translation"
# Requires: HEYGEN_API_KEY env var
set -euo pipefail

TYPE="${1:?Usage: poll-status.sh <video|translation> <id> [timeout_minutes]}"
ID="${2:?Usage: poll-status.sh <video|translation> <id> [timeout_minutes]}"
TIMEOUT_MIN="${3:-25}"

DEADLINE=$(($(date +%s) + TIMEOUT_MIN * 60))
INTERVAL=15

echo "Polling $TYPE $ID (timeout: ${TIMEOUT_MIN}m)..."

while true; do
  NOW=$(date +%s)
  if [ "$NOW" -ge "$DEADLINE" ]; then
    echo "::error::Timed out after ${TIMEOUT_MIN} minutes"
    exit 1
  fi

  if [ "$TYPE" = "video" ]; then
    RESULT=$(heygen video get "$ID" 2>/dev/null || echo '{}')
    STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('status','unknown'))" 2>/dev/null || echo "unknown")
  elif [ "$TYPE" = "translation" ]; then
    RESULT=$(heygen video-translate get "$ID" 2>/dev/null || echo '{}')
    STATUS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('status','unknown'))" 2>/dev/null || echo "unknown")
  else
    echo "::error::Unknown type: $TYPE (expected 'video' or 'translation')"
    exit 1
  fi

  REMAINING=$(( (DEADLINE - NOW) / 60 ))
  echo "  Status: $STATUS (${REMAINING}m remaining)"

  case "$STATUS" in
    completed)
      echo "$RESULT"
      exit 0
      ;;
    failed|error)
      echo "::error::$TYPE $ID failed"
      echo "$RESULT"
      exit 1
      ;;
    *)
      sleep "$INTERVAL"
      # Back off slightly for long-running jobs
      if [ "$INTERVAL" -lt 60 ]; then
        INTERVAL=$((INTERVAL + 5))
      fi
      ;;
  esac
done
