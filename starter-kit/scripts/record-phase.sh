#!/bin/sh
# Atomically record one phase transition and a privacy-safe receipt digest.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PHASE="${1:-}"
STATUS="${2:-}"
RECEIPT="${3:-}"
LEDGER="${4:-$ROOT/state/build-ledger.json}"
case "$PHASE" in preflight|human_bootstrap|local_foundation|infrastructure|pre_cutover_verification|cutover_acceptance|agent_layer|resilience_handoff) ;; *) echo "ERROR: invalid phase" >&2; exit 2 ;; esac
case "$STATUS" in in_progress|awaiting_human|blocked|completed) ;; *) echo "ERROR: invalid status" >&2; exit 2 ;; esac
[ -f "$LEDGER" ] && [ ! -L "$LEDGER" ] || { echo "ERROR: unsafe or missing ledger" >&2; exit 1; }
[ -f "$RECEIPT" ] && [ ! -L "$RECEIPT" ] || { echo "ERROR: unsafe or missing receipt" >&2; exit 1; }
CURRENT=$(jq -r --arg phase "$PHASE" '.phases[] | select(.key==$phase) | .status' "$LEDGER")
[ -n "$CURRENT" ] || { echo "ERROR: phase missing from ledger" >&2; exit 1; }
if [ "$CURRENT" = completed ] && [ "$STATUS" != completed ]; then
  echo "ERROR: completed phase is immutable" >&2
  exit 1
fi
HASH=$(shasum -a 256 "$RECEIPT" | awk '{print $1}')
RECEIPT_ID=$(basename "$RECEIPT")
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TMP=$(mktemp "${LEDGER}.tmp.XXXXXX")
trap 'rm -f "$TMP"' EXIT HUP INT TERM
jq --arg phase "$PHASE" --arg status "$STATUS" --arg now "$NOW" --arg id "$RECEIPT_ID" --arg hash "$HASH" '
  .updated_at=$now |
  .phases |= map(if .key==$phase then .status=$status | .receipts += [{id:$id, sha256:$hash, recorded_at:$now}] else . end)
' "$LEDGER" > "$TMP"
chmod 600 "$TMP"
mv "$TMP" "$LEDGER"
trap - EXIT HUP INT TERM
printf '%s\n' "PHASE-RECORDED $PHASE $STATUS"

