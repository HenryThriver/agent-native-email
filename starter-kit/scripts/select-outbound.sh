#!/bin/sh
# Atomically select relay or direct outbound in an already-rendered tree.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
MODE=${1:?usage: select-outbound.sh relay|direct [gate-receipt] [rendered-dir]}
RECEIPT=${2:-}
RENDERED=${3:-${ANE_RENDERED:-$ROOT/rendered}}
MAIL_DIR="$RENDERED/etc/mail"
ACTIVE="$MAIL_DIR/smtpd.conf"

[ -d "$MAIL_DIR" ] || { printf '%s\n' "ERROR: render the starter first" >&2; exit 1; }

case "$MODE" in
	relay)
		SOURCE="$MAIL_DIR/smtpd.conf.relay"
		;;
	direct)
		[ -n "$RECEIPT" ] && [ -f "$RECEIPT" ] && [ ! -L "$RECEIPT" ] || {
			printf '%s\n' "ERROR: direct mode requires a regular, non-symlink gate receipt" >&2
			exit 1
		}
		jq -e '
			.schema_version == 1 and
			.human_approved == true and
			.port25_egress == true and
			.ptr_fcrdns == true and
			.spf_aligned == true and
			.dkim_aligned == true and
			.dmarc_aligned == true and
			.deliverability_passed == true and
			.rollback_relay_ready == true
		' "$RECEIPT" >/dev/null || {
			printf '%s\n' "ERROR: direct-send gate receipt did not pass every check" >&2
			exit 1
		}
		SOURCE="$MAIL_DIR/smtpd.conf.direct"
		;;
	*)
		printf '%s\n' "ERROR: mode must be relay or direct" >&2
		exit 1
		;;
esac

[ -r "$SOURCE" ] || { printf '%s\n' "ERROR: outbound candidate is missing" >&2; exit 1; }
TEMP="$ACTIVE.new.$$"
trap 'rm -f "$TEMP"' EXIT HUP INT TERM
cp "$SOURCE" "$TEMP"
mv -f "$TEMP" "$ACTIVE"
trap - EXIT HUP INT TERM
printf 'OUTBOUND-SELECTED %s\n' "$MODE"
