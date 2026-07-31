#!/usr/bin/env bash
# Prerequisite: Docker Desktop (Windows/macOS) or Docker Engine (Linux) must
# be installed and running -- https://docs.docker.com/get-docker/
#
# Installs the `md-lint` command so it can be run from any directory, on any
# user account, without needing to keep this cloned repo around.
#
# Works on macOS, Linux, and Windows via Git Bash (Git for Windows ships bash).
#
# What it does:
#   1. Copies the Docker project files (Dockerfile, entrypoint.sh, package.json,
#      .markdownlint-cli2.jsonc) to $HOME/.md-lint -- this becomes the Docker
#      build context that `md-lint` uses no matter where it's invoked from.
#   2. Copies md-lint/md-lint (+ md-lint/md-lint.cmd on Windows) to a bin
#      directory and makes sure that directory is on PATH.
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker not found on PATH. Install Docker Desktop/Engine first: https://docs.docker.com/get-docker/" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MDLINT_HOME="$HOME/.md-lint"

echo "Installing markdown-reformatter project files to $MDLINT_HOME ..."
mkdir -p "$MDLINT_HOME"
cp "$REPO_DIR/Dockerfile" "$MDLINT_HOME/"
cp "$REPO_DIR/entrypoint.sh" "$MDLINT_HOME/"
cp "$REPO_DIR/package.json" "$MDLINT_HOME/"
cp "$REPO_DIR/.markdownlint-cli2.jsonc.example" "$MDLINT_HOME/"

# .markdownlint-cli2.jsonc is gitignored (each clone/install customizes its
# own rules) -- bootstrap it from the example, but never overwrite an existing
# customized config on re-install.
if [ ! -f "$MDLINT_HOME/.markdownlint-cli2.jsonc" ]; then
  cp "$MDLINT_HOME/.markdownlint-cli2.jsonc.example" "$MDLINT_HOME/.markdownlint-cli2.jsonc"
  echo "Created $MDLINT_HOME/.markdownlint-cli2.jsonc from the example -- edit it to customize rules."
fi

# Pick a bin directory: prefer one that's already on PATH, otherwise default
# to $HOME/bin (created if needed).
BIN_DIR=""
for candidate in "$HOME/bin" "$HOME/.local/bin"; do
  case ":$PATH:" in
    *":$candidate:"*)
      if [ -d "$candidate" ] || mkdir -p "$candidate" 2>/dev/null; then
        BIN_DIR="$candidate"
        break
      fi
      ;;
  esac
done
if [ -z "$BIN_DIR" ]; then
  BIN_DIR="$HOME/bin"
  mkdir -p "$BIN_DIR"
fi

echo "Installing md-lint command to $BIN_DIR ..."
cp "$REPO_DIR/md-lint/md-lint" "$BIN_DIR/md-lint"
chmod +x "$BIN_DIR/md-lint"

# On Windows (Git Bash/MSYS), also install the .cmd shim so `md-lint` works
# from PowerShell/cmd.exe, not just from Git Bash.
case "${OSTYPE:-}" in
  msys*|cygwin*)
    cp "$REPO_DIR/md-lint/md-lint.cmd" "$BIN_DIR/md-lint.cmd"
    ;;
esac

echo
echo "Done. Installed: $BIN_DIR/md-lint"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "You can now run 'md-lint <path>' from any directory."
    ;;
  *)
    echo "NOTE: $BIN_DIR is not on your PATH yet. Add it, then restart your terminal:"
    echo
    echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.bashrc   # bash"
    echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc    # zsh"
    if command -v cygpath >/dev/null 2>&1; then
      WIN_BIN_DIR="$(cygpath -w "$BIN_DIR")"
      echo "  setx PATH \"%PATH%;$WIN_BIN_DIR\"                   # Windows (run in a new terminal after)"
    fi
    ;;
esac
