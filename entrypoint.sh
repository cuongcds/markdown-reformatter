#!/bin/sh
# Runs markdownlint-cli2 --fix repeatedly until it converges (some rules only
# become fixable after an earlier rule's fix is applied), then does one final
# lint pass so any remaining (non-auto-fixable) issues are still reported.
set -e

DEFAULT_CONFIG="/app/.markdownlint-cli2.jsonc"
CONFIG="/data/.markdownlint-cli2.jsonc"

# Use the target directory's own config if it already has one; otherwise seed
# it with a copy of the default so the target folder ends up with its own
# editable config too (instead of always using a config outside /data).
if [ ! -f "$CONFIG" ]; then
  cp "$DEFAULT_CONFIG" "$CONFIG"
  echo "No .markdownlint-cli2.jsonc in the target directory -- copied the default one there." >&2
fi

if [ "$1" = "--check" ]; then
  shift
  GLOBS="${*:-**/*.md}"
  exec npx --prefix /app markdownlint-cli2 --config "$CONFIG" $GLOBS
fi

GLOBS="${*:-**/*.md}"

MAX_PASSES=5
i=1
while [ "$i" -le "$MAX_PASSES" ]; do
  set +e
  OUTPUT=$(npx --prefix /app markdownlint-cli2 --config "$CONFIG" --fix $GLOBS 2>&1)
  STATUS=$?
  set -e
  echo "$OUTPUT"
  if [ "$STATUS" -eq 0 ]; then
    break
  fi
  # Stop early once a pass fixes nothing more (remaining issues aren't auto-fixable).
  if ! echo "$OUTPUT" | grep -q 'Attempted:'; then
    break
  fi
  i=$((i + 1))
done

echo "--- final check ---"
npx --prefix /app markdownlint-cli2 --config "$CONFIG" $GLOBS
