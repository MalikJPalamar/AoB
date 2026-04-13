#!/bin/bash
# Local development: install HeyGen CLI
# For CI, use .github/scripts/setup-cli.sh instead
set -euo pipefail

echo "Installing HeyGen CLI..."
curl -fsSL https://static.heygen.ai/cli/install.sh | bash

echo ""
echo "Done. Run 'heygen auth status' to verify."
echo "Set HEYGEN_API_KEY in your environment or run 'heygen auth login'."
