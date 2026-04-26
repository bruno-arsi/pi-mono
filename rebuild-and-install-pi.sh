#!/usr/bin/env bash
#
# Full rebuild of pi-mono and global install of the `pi` CLI,
# overwriting any existing `pi` binary on PATH.
#
# Usage:
#   ./rebuild-and-install-pi.sh
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "==> Repo: $REPO_ROOT"

if [[ -x "$(command -v pi || true)" ]]; then
  EXISTING_PI="$(command -v pi)"
  echo "==> Existing pi found at: $EXISTING_PI (will be overwritten)"
else
  echo "==> No existing pi on PATH"
fi

echo "==> Cleaning workspace build outputs..."
npm run clean

echo "==> Removing node_modules for a clean install..."
rm -rf node_modules packages/*/node_modules

echo "==> Installing dependencies (npm install)..."
npm install

echo "==> Building all packages..."
npm run build

echo "==> Installing pi CLI globally from packages/coding-agent..."
# `npm install -g .` installs the package's `bin` entries into the npm prefix,
# overwriting any existing `pi` symlink/binary at $(npm prefix -g)/bin/pi.
npm install -g --force ./packages/coding-agent

INSTALLED_PI="$(command -v pi || true)"
if [[ -z "$INSTALLED_PI" ]]; then
  echo "ERROR: pi was not found on PATH after install." >&2
  echo "Make sure $(npm prefix -g)/bin is on your PATH." >&2
  exit 1
fi

echo ""
echo "==> Done."
echo "    pi installed at: $INSTALLED_PI"
pi --version || true
