#!/usr/bin/env bash
set -euo pipefail

# AdamAI public installer.
# This file is safe to run from curl/bash and does not require cloning the repo.

RELEASE_REPO="${ADAMAI_RELEASE_REPO:-KingMinerThailand/adamai-release}"
DEFAULT_RELEASE_URL="https://github.com/${RELEASE_REPO}/releases/latest/download/adamai-local-beta.tgz"
RELEASE_URL="${ADAMAI_RELEASE_URL:-$DEFAULT_RELEASE_URL}"
INSTALL_DIR="${ADAMAI_INSTALL_DIR:-$HOME/AdamAI}"
INSTALL_PROFILE="${ADAMAI_INSTALL_PROFILE:-starter}"
TMP_FILE="$(mktemp -t adamai-local-beta.XXXXXX.tgz)"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    case "$1" in
      node|npm) echo "Install Node.js 20+ from https://nodejs.org/ or your system package manager." >&2 ;;
      curl) echo "Install curl with your system package manager." >&2 ;;
      tar) echo "Install tar with your system package manager." >&2 ;;
    esac
    exit 1
  fi
}

need curl
need tar
need node
need npm

mkdir -p "$INSTALL_DIR"
echo "AdamAI installer"
echo "Release: $RELEASE_URL"
echo "Repo:    $RELEASE_REPO"
echo "Target:  $INSTALL_DIR"
echo "Profile: $INSTALL_PROFILE"
echo

curl -fsSL --proto '=https' --tlsv1.2 "$RELEASE_URL" -o "$TMP_FILE"
tar -xzf "$TMP_FILE" -C "$INSTALL_DIR" --strip-components=1
rm -f "$TMP_FILE"

cd "$INSTALL_DIR"
npm run install:local -- --yes --profile="$INSTALL_PROFILE"

echo
echo "Running AdamAI doctor..."
if ! npm run doctor; then
  echo
  echo "Doctor found issues to review. AdamAI was installed; rerun 'npm run doctor' after fixing prerequisites."
fi

echo
echo "AdamAI installed."
echo "Start with: cd \"$INSTALL_DIR\" && npm run start:local"
echo "Open Hub:   http://127.0.0.1:3200"
if [ "$INSTALL_PROFILE" = "automation" ]; then
  echo "Open n8n:   http://127.0.0.1:5678 or http://127.0.0.1:3200/n8n"
fi
