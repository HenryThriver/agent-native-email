#!/bin/bash
# Create and remove ownership-marked scratch directories. Cleanup fails closed.
set -euo pipefail

usage() {
  printf '%s\n' 'Usage: safe-scratch.sh create PREFIX | cleanup ABSOLUTE_PATH' >&2
  exit 2
}

[ "$#" -ge 1 ] || usage
ACTION="$1"
shift
TMP_ROOT="${TMPDIR:-/tmp}"
[ -d "$TMP_ROOT" ] || { echo "ERROR: temporary root does not exist" >&2; exit 1; }
TMP_ROOT="$(cd "$TMP_ROOT" && pwd -P)"
MARKER_NAME=".agent-native-email-scratch"

TRUSTED_TMP=0
SYSTEM_TMP="$(cd /tmp && pwd -P)"
case "$TMP_ROOT" in "$SYSTEM_TMP"|"$SYSTEM_TMP"/*) TRUSTED_TMP=1 ;; esac
if [ "$TRUSTED_TMP" -eq 0 ] && [ -d /var/tmp ]; then
  SYSTEM_VAR_TMP="$(cd /var/tmp && pwd -P)"
  case "$TMP_ROOT" in "$SYSTEM_VAR_TMP"|"$SYSTEM_VAR_TMP"/*) TRUSTED_TMP=1 ;; esac
fi
if [ "$TRUSTED_TMP" -eq 0 ] && command -v getconf >/dev/null; then
  DARWIN_TMP="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)"
  if [ -n "$DARWIN_TMP" ] && [ -d "$DARWIN_TMP" ]; then
    DARWIN_TMP="$(cd "$DARWIN_TMP" && pwd -P)"
    case "$TMP_ROOT" in "$DARWIN_TMP"|"$DARWIN_TMP"/*) TRUSTED_TMP=1 ;; esac
  fi
fi
[ "$TRUSTED_TMP" -eq 1 ] || { echo "ERROR: untrusted TMPDIR" >&2; exit 1; }
if command -v git >/dev/null && git -C "$TMP_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: a repository cannot be used as TMPDIR" >&2
  exit 1
fi

owner_uid() {
  if [ "$(uname -s)" = "Darwin" ]; then stat -f '%u' "$1"; else stat -c '%u' "$1"; fi
}

file_mode() {
  if [ "$(uname -s)" = "Darwin" ]; then stat -f '%Lp' "$1"; else stat -c '%a' "$1"; fi
}

case "$ACTION" in
  create)
    [ "$#" -eq 1 ] || usage
    PREFIX="$1"
    [[ "$PREFIX" =~ ^[a-z0-9][a-z0-9_-]{0,31}$ ]] || {
      echo "ERROR: invalid scratch prefix" >&2
      exit 1
    }
    TARGET="$(mktemp -d "$TMP_ROOT/agent-native-email-$PREFIX.XXXXXX")"
    TARGET="$(cd "$TARGET" && pwd -P)"
    chmod 700 "$TARGET"
    printf 'version=1\nuid=%s\npath=%s\n' "$(id -u)" "$TARGET" > "$TARGET/$MARKER_NAME"
    chmod 600 "$TARGET/$MARKER_NAME"
    printf '%s\n' "$TARGET"
    ;;
  cleanup)
    [ "$#" -eq 1 ] || usage
    REQUESTED="$1"
    case "$REQUESTED" in
      /*/../*|*/..|../*|*/./*|*/.|*//*|'') echo "ERROR: unsafe scratch path" >&2; exit 1 ;;
      /*) ;;
      *) echo "ERROR: scratch path must be absolute" >&2; exit 1 ;;
    esac
    [ -d "$REQUESTED" ] && [ ! -L "$REQUESTED" ] || { echo "ERROR: unsafe scratch directory" >&2; exit 1; }
    TARGET="$(cd "$REQUESTED" && pwd -P)"
    [ "$(dirname "$TARGET")" = "$TMP_ROOT" ] || { echo "ERROR: scratch is not a direct child of TMPDIR" >&2; exit 1; }
    [[ "$(basename "$TARGET")" =~ ^agent-native-email-[a-z0-9][a-z0-9_-]{0,31}\.[A-Za-z0-9]+$ ]] || { echo "ERROR: unexpected scratch name" >&2; exit 1; }
    [ "$(owner_uid "$TARGET")" = "$(id -u)" ] && [ "$(file_mode "$TARGET")" = "700" ] || { echo "ERROR: scratch ownership or mode mismatch" >&2; exit 1; }
    MARKER="$TARGET/$MARKER_NAME"
    [ -f "$MARKER" ] && [ ! -L "$MARKER" ] || { echo "ERROR: scratch marker missing" >&2; exit 1; }
    [ "$(owner_uid "$MARKER")" = "$(id -u)" ] && [ "$(file_mode "$MARKER")" = "600" ] || { echo "ERROR: marker ownership or mode mismatch" >&2; exit 1; }
    EXPECTED="$(printf 'version=1\nuid=%s\npath=%s' "$(id -u)" "$TARGET")"
    [ "$(cat "$MARKER")" = "$EXPECTED" ] || { echo "ERROR: scratch marker mismatch" >&2; exit 1; }
    rm -rf -- "$TARGET"
    ;;
  *) usage ;;
esac

