#!/bin/sh
# Verify that webmail renders a login form, not merely an HTTP 200 error page.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PUBLIC_CONFIG="${ANE_PUBLIC_CONFIG:-$ROOT/config/public.env}"

check_body() {
	BODY_FILE=$1
	[ -r "$BODY_FILE" ] || { printf '%s\n' "ERROR: unreadable webmail body" >&2; exit 1; }
	if grep -qi 'Oops\.\.\. something went wrong' "$BODY_FILE"; then
		printf '%s\n' "ERROR: Roundcube internal-error page detected" >&2
		exit 1
	fi
	grep -q 'name="_user"' "$BODY_FILE" || { printf '%s\n' "ERROR: username field missing" >&2; exit 1; }
	grep -q 'name="_pass"' "$BODY_FILE" || { printf '%s\n' "ERROR: password field missing" >&2; exit 1; }
}

if [ "${1:-}" = "--body-file" ]; then
	check_body "${2:?--body-file requires a fixture path}"
	printf '%s\n' "WEBMAIL-BODY-OK"
	exit 0
fi

[ -r "$PUBLIC_CONFIG" ] || { printf '%s\n' "ERROR: missing public config" >&2; exit 1; }
MAIL_HOST=$(awk -F= '$1 == "MAIL_HOST" { print substr($0, 11) }' "$PUBLIC_CONFIG")
[ -n "$MAIL_HOST" ] || { printf '%s\n' "ERROR: MAIL_HOST is missing" >&2; exit 1; }
BASE_URL=${1:-https://$MAIL_HOST/webmail/}
BODY=$(mktemp)
cleanup() { rm -f "$BODY"; }
trap cleanup EXIT HUP INT TERM

STATUS=$(curl -sS -o "$BODY" -w '%{http_code}' "$BASE_URL")
[ "$STATUS" = "200" ] || { printf 'ERROR: webmail returned HTTP %s\n' "$STATUS" >&2; exit 1; }
check_body "$BODY"

PROTECTED_STATUS=$(curl -sS -o /dev/null -w '%{http_code}' \
	"${BASE_URL%/}/config/config.inc.php")
[ "$PROTECTED_STATUS" = "404" ] || {
	printf 'ERROR: protected Roundcube config returned HTTP %s\n' "$PROTECTED_STATUS" >&2
	exit 1
}

printf '%s\n' "WEBMAIL-LIVE-OK"
