#!/bin/sh
# Resolve secret references only into the child process environment.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ENV_FILE="${1:-$ROOT/config/secrets.env.tpl}"
[ "$#" -ge 2 ] || { echo "usage: with-secrets.sh ENV_TEMPLATE COMMAND [ARGS...]" >&2; exit 2; }
shift
exec "$ROOT/scripts/op-service-account.sh" run --env-file="$ENV_FILE" -- "$@"

