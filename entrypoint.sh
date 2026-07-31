#!/bin/sh
# Runs markdownlint-cli2 --fix repeatedly until it converges (some rules only
# become fixable after an earlier rule's fix is applied), then does one final
# lint pass so any remaining (non-auto-fixable) issues are still reported.
set -e

CONFIG="/app/.markdownlint-cli2.jsonc"

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
