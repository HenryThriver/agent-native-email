#!/bin/bash
# Run 1Password CLI with a vault-scoped service account, never desktop auth.
set -euo pipefail

BOOTSTRAP="${ANE_BOOTSTRAP:-$HOME/.config/agent-native-email/1password.env}"
REAL_OP="${OP_REAL_BINARY:-/opt/homebrew/bin/op}"
[ -r "$BOOTSTRAP" ] || { echo "ERROR: missing service-account bootstrap" >&2; exit 1; }
[ -x "$REAL_OP" ] || { echo "ERROR: 1Password CLI not found" >&2; exit 1; }

set -a
# shellcheck disable=SC1090
. "$BOOTSTRAP"
set +a
[ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ] || { echo "ERROR: service-account token is not configured" >&2; exit 1; }

export OP_LOAD_DESKTOP_APP_SETTINGS=false
export OP_BIOMETRIC_UNLOCK_ENABLED=false
export OP_CACHE=false
exec "$REAL_OP" --cache=false "$@"

