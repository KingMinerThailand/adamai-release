#!/usr/bin/env bash
set -euo pipefail

# AdamAI public installer.
# This file is safe to run from curl/bash and does not require cloning the repo.

RELEASE_REPO="${ADAMAI_RELEASE_REPO:-KingMinerThailand/adamai-release}"
DEFAULT_RELEASE_URL="https://github.com/${RELEASE_REPO}/releases/latest/download/adamai-local-beta.tgz"
RELEASE_URL="${ADAMAI_RELEASE_URL:-$DEFAULT_RELEASE_URL}"
INSTALL_DIR="${ADAMAI_INSTALL_DIR:-$HOME/AdamAI}"
INSTALL_PROFILE="${ADAMAI_INSTALL_PROFILE:-starter}"
NODE_MAJOR="${ADAMAI_NODE_MAJOR:-24}"
NODE_HOME="${ADAMAI_NODE_HOME:-$HOME/.adamai/node-v${NODE_MAJOR}}"
TMP_FILE="$(mktemp -t adamai-local-beta.XXXXXX.tgz)"
TMP_NODE_DIR=""

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1" >&2
    case "$1" in
      curl) echo "Install curl with your system package manager." >&2 ;;
      tar) echo "Install tar with your system package manager." >&2 ;;
    esac
    exit 1
  fi
}

cleanup() {
  rm -f "$TMP_FILE"
  if [ -n "${TMP_NODE_DIR:-}" ] && [ -d "$TMP_NODE_DIR" ]; then
    rm -rf "$TMP_NODE_DIR"
  fi
}
trap cleanup EXIT

node_major() {
  node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || echo 0
}

has_working_node() {
  command -v node >/dev/null 2>&1 \
    && command -v npm >/dev/null 2>&1 \
    && [ "$(node_major)" -ge 18 ]
}

node_platform() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    Linux) echo "linux" ;;
    *) return 1 ;;
  esac
}

node_arch() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64) echo "x64" ;;
    *) return 1 ;;
  esac
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "Missing dependency: shasum or sha256sum" >&2
    exit 1
  fi
}

persist_node_path() {
  local profile_file=""
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  if [ "$shell_name" = "zsh" ]; then
    profile_file="$HOME/.zshrc"
  elif [ "$shell_name" = "bash" ]; then
    profile_file="$HOME/.bashrc"
  elif [ -f "$HOME/.zshrc" ]; then
    profile_file="$HOME/.zshrc"
  else
    profile_file="$HOME/.profile"
  fi

  mkdir -p "$(dirname "$profile_file")"
  touch "$profile_file"
  if ! grep -F "$NODE_HOME/bin" "$profile_file" >/dev/null 2>&1; then
    {
      echo ""
      echo "# AdamAI portable Node.js"
      echo "export PATH=\"$NODE_HOME/bin:\$PATH\""
    } >> "$profile_file"
    echo "Added Node.js to PATH in $profile_file"
  fi
}

install_portable_node() {
  local platform arch sums filename expected url archive actual
  platform="$(node_platform)" || {
    echo "Unsupported OS for automatic Node.js install: $(uname -s)" >&2
    echo "Install Node.js ${NODE_MAJOR} LTS from https://nodejs.org/ and rerun this installer." >&2
    exit 1
  }
  arch="$(node_arch)" || {
    echo "Unsupported CPU for automatic Node.js install: $(uname -m)" >&2
    echo "Install Node.js ${NODE_MAJOR} LTS from https://nodejs.org/ and rerun this installer." >&2
    exit 1
  }

  echo "Node.js 18+ was not found. Installing portable Node.js ${NODE_MAJOR} LTS for AdamAI..."
  TMP_NODE_DIR="$(mktemp -d -t adamai-node.XXXXXX)"
  sums="$(curl -fsSL --proto '=https' --tlsv1.2 "https://nodejs.org/dist/latest-v${NODE_MAJOR}.x/SHASUMS256.txt")"
  filename="$(printf '%s\n' "$sums" | awk -v pattern="node-v[0-9.]+-${platform}-${arch}\\.tar\\.gz$" '$2 ~ pattern { print $2; exit }')"
  if [ -z "$filename" ]; then
    echo "Could not find Node.js ${NODE_MAJOR} LTS binary for ${platform}-${arch}." >&2
    exit 1
  fi
  expected="$(printf '%s\n' "$sums" | awk -v file="$filename" '$2 == file { print $1; exit }')"
  url="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x/${filename}"
  archive="$TMP_NODE_DIR/$filename"

  curl -fsSL --proto '=https' --tlsv1.2 "$url" -o "$archive"
  actual="$(sha256_file "$archive")"
  if [ "$actual" != "$expected" ]; then
    echo "Node.js download checksum mismatch." >&2
    exit 1
  fi

  rm -rf "$NODE_HOME"
  mkdir -p "$NODE_HOME"
  tar -xzf "$archive" -C "$NODE_HOME" --strip-components=1
  export PATH="$NODE_HOME/bin:$PATH"
  persist_node_path
  echo "Installed $(node -v) at $NODE_HOME"
}

ensure_node() {
  if has_working_node; then
    echo "Using Node.js $(node -v) and npm $(npm -v)"
    return
  fi
  install_portable_node
  if ! has_working_node; then
    echo "Node.js install did not produce a working node/npm command." >&2
    exit 1
  fi
}

need curl
need tar
ensure_node

mkdir -p "$INSTALL_DIR"
echo "AdamAI installer"
echo "Release: $RELEASE_URL"
echo "Repo:    $RELEASE_REPO"
echo "Target:  $INSTALL_DIR"
echo "Profile: $INSTALL_PROFILE"
echo

curl -fsSL --proto '=https' --tlsv1.2 "$RELEASE_URL" -o "$TMP_FILE"
rm -rf "$INSTALL_DIR/command-hub/public/data/growth"
tar -xzf "$TMP_FILE" -C "$INSTALL_DIR" --strip-components=1

cd "$INSTALL_DIR"
npm run install:local -- --yes --profile="$INSTALL_PROFILE"
npm run runtime:protect -- --force

node <<'NODE'
const crypto = require("crypto");
const fs = require("fs");
const os = require("os");
const path = require("path");

const target = path.resolve(process.cwd());
const manifest = path.join(target, "ADAMAI-RUNTIME-MANIFEST.json");
if (!fs.existsSync(manifest)) process.exit(0);

const sha256File = (file) => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
const id = crypto.createHash("sha256").update(target).digest("hex").slice(0, 24);
const stateFile = path.join(os.homedir(), ".adamai", "installations", `${id}.json`);
fs.mkdirSync(path.dirname(stateFile), { recursive: true });
fs.writeFileSync(stateFile, `${JSON.stringify({
  target,
  manifest: "ADAMAI-RUNTIME-MANIFEST.json",
  manifest_sha256: sha256File(manifest),
  recorded_at: new Date().toISOString(),
  cli_version: "direct-installer",
}, null, 2)}\n`, { mode: 0o600 });
NODE

echo
echo "Running AdamAI doctor..."
if ! npm run doctor; then
  echo
  echo "Doctor found issues to review. AdamAI was installed; rerun 'npm run doctor' after fixing prerequisites."
fi

echo
echo "AdamAI installed."
echo "Start with: cd \"$INSTALL_DIR\" && npm run start:local"
if [ -d "$NODE_HOME/bin" ]; then
  echo "Node path:  export PATH=\"$NODE_HOME/bin:\$PATH\""
fi
echo "Open Hub:   http://127.0.0.1:3200"
if [ "$INSTALL_PROFILE" = "automation" ]; then
  echo "Open n8n:   http://127.0.0.1:5678 or http://127.0.0.1:3200/n8n"
fi
