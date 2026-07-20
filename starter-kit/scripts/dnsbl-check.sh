#!/bin/sh
# Check an IPv4 address only after proving the DNSBL path can report a hit.
# Exit 0 clean, 1 listed, 2 checker unavailable/invalid.
set -eu

DIG=${DNSBL_DIG:-dig}
LISTS='zen.spamhaus.org b.barracudacentral.org bl.spamcop.net psbl.surriel.com'

query() { "$DIG" +short "$1" A 2>/dev/null || true; }
reverse_ip() { printf '%s\n' "$1" | awk -F. '{print $4"."$3"."$2"."$1}'; }

self_test() {
  FAILED=0
  for BL in $LISTS; do
    RESULT=$(query "2.0.0.127.$BL")
    if [ -n "$RESULT" ]; then
      printf '%s\n' "available $BL"
    else
      printf '%s\n' "UNAVAILABLE $BL" >&2
      FAILED=1
    fi
  done
  [ "$FAILED" -eq 0 ] || return 2
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
  exit $?
fi

[ "$#" -eq 1 ] || { echo "usage: dnsbl-check.sh --self-test | IPV4" >&2; exit 2; }
IP="$1"
printf '%s' "$IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || { echo "ERROR: invalid IPv4" >&2; exit 2; }
printf '%s\n' "$IP" | awk -F. '{ for (i=1;i<=4;i++) if ($i > 255) exit 1 }' || { echo "ERROR: invalid IPv4 octet" >&2; exit 2; }
self_test >/dev/null

REV=$(reverse_ip "$IP")
LISTED=0
for BL in $LISTS; do
  RESULT=$(query "$REV.$BL")
  if [ -n "$RESULT" ]; then
    printf '%s\n' "LISTED $BL $RESULT"
    LISTED=1
  else
    printf '%s\n' "clean $BL"
  fi
done
exit "$LISTED"

