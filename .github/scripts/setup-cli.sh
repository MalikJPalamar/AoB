#!/bin/bash
# Install and configure HeyGen CLI for GitHub Actions runners
set -euo pipefail

echo "::group::Install HeyGen CLI"
curl -fsSL https://static.heygen.ai/cli/install.sh | bash
echo "$HOME/.local/bin" >> "$GITHUB_PATH"
export PATH="$HOME/.local/bin:$PATH"
echo "::endgroup::"

echo "::group::Verify installation"
heygen --version
heygen auth status
echo "::endgroup::"
