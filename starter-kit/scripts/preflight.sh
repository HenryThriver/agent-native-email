#!/bin/sh
# Read-only local capability and public-DNS inventory.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
CONFIG="${1:-$ROOT/config/public.env}"
DOMAIN=""
if [ -r "$CONFIG" ]; then
  DOMAIN=$(awk -F= '$1 == "DOMAIN" { print substr($0, 8) }' "$CONFIG")
fi

printf '%s\n' "agent-native-email preflight"
printf '%s\n' "os=$(uname -s) arch=$(uname -m)"
if command -v sw_vers >/dev/null 2>&1; then
  printf '%s\n' "macos=$(sw_vers -productVersion)"
fi

for CMD in git ssh curl jq dig rsync shasum; do
  if command -v "$CMD" >/dev/null 2>&1; then
    printf '%s\n' "$CMD=present"
  else
    printf '%s\n' "$CMD=missing"
  fi
done
for CMD in brew op mbsync notmuch msmtp; do
  if command -v "$CMD" >/dev/null 2>&1; then
    printf '%s\n' "$CMD=present-optional"
  else
    printf '%s\n' "$CMD=missing-optional"
  fi
done

if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "example.com" ]; then
  printf '%s\n' "DOMAIN-OWNERSHIP-REQUIRED: configure a domain you own before infrastructure work" >&2
  exit 2
fi

printf '%s\n' "domain-prerequisite=configured-human-ownership-proof-required"
if command -v dig >/dev/null 2>&1; then
  printf '%s\n' "dns-domain=$DOMAIN"
  for TYPE in NS MX TXT; do
    printf '%s\n' "dns-$TYPE-begin"
    dig +short "$DOMAIN" "$TYPE" || true
    printf '%s\n' "dns-$TYPE-end"
  done
fi
