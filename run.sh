#!/usr/bin/env bash
# Prerequisite: Docker Desktop (Windows/macOS) or Docker Engine (Linux) must
# be installed and running -- https://docs.docker.com/get-docker/
#
# Run this from the cloned repo (any OS with bash + Docker): ./run.sh /path/to/markdown/dir [--check]
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Docker not found on PATH. Install Docker Desktop/Engine first: https://docs.docker.com/get-docker/" >&2
  exit 1
fi

TARGET_DIR="${1:?Usage: ./run.sh /path/to/markdown/dir [--check]}"
MODE="${2:-}"

# Use this script's own directory as the Docker build context, so it works
# regardless of the caller's current directory (e.g. `../run.sh path` or a
# full path to run.sh from elsewhere).
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .markdownlint-cli2.jsonc is gitignored (each clone customizes its own rules)
# -- bootstrap it from the tracked example on first run.
if [ ! -f "$PROJECT_DIR/.markdownlint-cli2.jsonc" ]; then
  cp "$PROJECT_DIR/.markdownlint-cli2.jsonc.example" "$PROJECT_DIR/.markdownlint-cli2.jsonc"
  echo "Created $PROJECT_DIR/.markdownlint-cli2.jsonc from the example -- edit it to customize rules." >&2
fi

RESOLVED="$(cd "$TARGET_DIR" && pwd)"

# On Git Bash/MSYS (Windows), Docker Desktop needs a native Windows path (C:/...)
# for -v bind mounts -- the MSYS-style /c/... path silently mounts an empty dir.
if command -v cygpath >/dev/null 2>&1; then
  RESOLVED="$(cygpath -m "$RESOLVED")"
  PROJECT_DIR="$(cygpath -m "$PROJECT_DIR")"
fi

# Swallow the Docker build log (noisy buildkit output) -- only show it if the
# build actually fails, so the lint output below isn't buried under it.
if ! BUILD_LOG=$(docker build -t markdown-reformatter "$PROJECT_DIR" 2>&1); then
  echo "$BUILD_LOG" >&2
  echo "Error: Docker build failed." >&2
  exit 1
fi

if [ "$MODE" = "--check" ]; then
  docker run --rm -v "${RESOLVED}:/data" markdown-reformatter --check "**/*.md"
else
  docker run --rm -v "${RESOLVED}:/data" markdown-reformatter "**/*.md"
fi
