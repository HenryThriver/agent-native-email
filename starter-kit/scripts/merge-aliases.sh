#!/bin/sh
# Preserve operator aliases and append only missing, valid managed keys.
set -eu
[ "$#" -eq 3 ] || { echo "usage: merge-aliases.sh BASE MANAGED OUTPUT" >&2; exit 2; }
BASE="$1"
MANAGED="$2"
OUTPUT="$3"
[ -r "$BASE" ] && [ -r "$MANAGED" ] || { echo "ERROR: unreadable alias input" >&2; exit 1; }
[ ! -e "$OUTPUT" ] || { echo "ERROR: refusing to overwrite alias output" >&2; exit 1; }

umask 077
cp "$BASE" "$OUTPUT"
while IFS= read -r LINE || [ -n "$LINE" ]; do
  case "$LINE" in ''|'#'*) continue ;; esac
  KEY=$(printf '%s\n' "$LINE" | sed -n 's/^[[:space:]]*\([A-Za-z0-9._+-][A-Za-z0-9._+-]*\)[[:space:]]*:.*/\1/p')
  [ -n "$KEY" ] || { echo "ERROR: invalid managed alias line" >&2; exit 1; }
  if awk -F: -v wanted="$KEY" '{ key=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key); if (key == wanted) found=1 } END { exit(found ? 0 : 1) }' "$OUTPUT"; then
    continue
  fi
  printf '%s\n' "$LINE" >> "$OUTPUT"
done < "$MANAGED"

