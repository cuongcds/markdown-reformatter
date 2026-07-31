#!/usr/bin/env bash
# Reverses install.sh: removes the md-lint command and its Docker project
# files copy. Safe to re-run (no-op if already uninstalled).
set -euo pipefail

MDLINT_HOME="$HOME/.md-lint"
removed_any=false

if [ -d "$MDLINT_HOME" ]; then
  rm -rf "$MDLINT_HOME"
  echo "Removed $MDLINT_HOME"
  removed_any=true
fi

# install.sh may have placed md-lint in either of these -- only remove files
# that actually look like our script (avoid deleting an unrelated md-lint).
for candidate in "$HOME/bin" "$HOME/.local/bin"; do
  f="$candidate/md-lint"
  if [ -f "$f" ] && grep -q 'PROJECT_DIR="\$HOME/\.md-lint"' "$f" 2>/dev/null; then
    rm -f "$f" "$candidate/md-lint.cmd"
    echo "Removed $f (and md-lint.cmd, if present)"
    removed_any=true
  fi
done

if [ "$removed_any" = false ]; then
  echo "Nothing to uninstall -- md-lint doesn't appear to be installed."
else
  echo
  echo "Uninstalled md-lint."
  echo "NOTE: if you manually added a bin dir to PATH in ~/.bashrc or ~/.zshrc"
  echo "for this, remove that line yourself -- this script only undoes what"
  echo "install.sh created."
fi

docker rmi markdown-reformatter >/dev/null 2>&1 && echo "Removed the markdown-reformatter Docker image." || true
