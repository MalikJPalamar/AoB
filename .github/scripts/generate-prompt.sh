#!/bin/bash
# Convert blog post content into a HeyGen video prompt via Claude API
# Usage: ./generate-prompt.sh <blog_file_path>
# Requires: ANTHROPIC_API_KEY, AVATAR_NAME, BRAND_NAME, BRAND_WEBSITE env vars
set -euo pipefail

BLOG_FILE="${1:?Usage: generate-prompt.sh <blog_file_path>}"

if [ ! -f "$BLOG_FILE" ]; then
  echo "::error::Blog file not found: $BLOG_FILE"
  exit 1
fi

# Truncate to 8000 chars to stay within limits
CONTENT=$(head -c 8000 "$BLOG_FILE")

RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d "$(python3 -c "
import json, sys, os
content = sys.stdin.read()
avatar = os.environ.get('AVATAR_NAME', 'the presenter')
brand = os.environ.get('BRAND_NAME', 'the brand')
website = os.environ.get('BRAND_WEBSITE', '')
cta = f'End with a call to action to visit {website}.' if website else ''
print(json.dumps({
    'model': 'claude-sonnet-4-20250514',
    'max_tokens': 1024,
    'messages': [{
        'role': 'user',
        'content': f'''Convert this blog post into a 60-second HeyGen Video Agent prompt.

The presenter is {avatar}, founder of {brand}.
Tone: warm, knowledgeable, grounded, passionate.
Extract the 3 most compelling points.
{cta}
Output ONLY the prompt text, nothing else.

Blog post:
{content}'''
    }]
}))
" <<< "$CONTENT")")

PROMPT=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['content'][0]['text'])")

if [ -z "$PROMPT" ]; then
  echo "::error::Failed to generate prompt"
  echo "$RESPONSE"
  exit 1
fi

echo "$PROMPT"
