#!/bin/sh
# Create a resumable phase ledger without overwriting prior state.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
MODE="${1:-}"
OUT="${2:-$ROOT/state/build-ledger.json}"
case "$MODE" in fresh|migration) ;; *) echo "usage: init-ledger.sh fresh|migration [path]" >&2; exit 2 ;; esac
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required" >&2; exit 1; }
[ ! -e "$OUT" ] || { echo "ERROR: ledger already exists" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
TMP=$(mktemp "${OUT}.tmp.XXXXXX")
trap 'rm -f "$TMP"' EXIT HUP INT TERM
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -n --arg now "$NOW" --arg mode "$MODE" '{
  schema_version: 1,
  guide_version: "0.1.1-experimental",
  mode: $mode,
  created_at: $now,
  updated_at: $now,
  phases: ["preflight","human_bootstrap","local_foundation","infrastructure","pre_cutover_verification","cutover_acceptance","agent_layer","resilience_handoff"] | map({key:., status:"pending", receipts:[]})
}' > "$TMP"
chmod 600 "$TMP"
mv "$TMP" "$OUT"
trap - EXIT HUP INT TERM
printf '%s\n' "LEDGER-CREATED $OUT"
