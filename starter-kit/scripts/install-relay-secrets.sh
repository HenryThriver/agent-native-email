#!/bin/sh
# Install OpenSMTPD relay credentials via stdin and atomic verified replacement.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PUBLIC_CONFIG="${ANE_PUBLIC_CONFIG:-$ROOT/config/public.env}"
[ -r "$PUBLIC_CONFIG" ] || { echo "ERROR: missing public config" >&2; exit 1; }
MAIL_USER=$(awk -F= '$1 == "MAIL_USER" { print substr($0, 11) }' "$PUBLIC_CONFIG")
MAIL_HOST=$(awk -F= '$1 == "MAIL_HOST" { print substr($0, 11) }' "$PUBLIC_CONFIG")
HOST="${MAIL_USER}@${1:-$MAIL_HOST}"
: "${SMTP2GO_USERNAME:?SMTP2GO_USERNAME is required}"
: "${SMTP2GO_PASSWORD:?SMTP2GO_PASSWORD is required}"
SMTP_USER="$SMTP2GO_USERNAME"
SMTP_PASS="$SMTP2GO_PASSWORD"
unset SMTP2GO_USERNAME SMTP2GO_PASSWORD

case "$SMTP_USER" in *:*|*[[:space:]]*) echo "ERROR: invalid relay username" >&2; exit 1 ;; esac
case "$SMTP_PASS" in *[[:space:]]*) echo "ERROR: relay password contains whitespace" >&2; exit 1 ;; esac

TABLE=$(printf 'smtp2go %s:%s\n' "$SMTP_USER" "$SMTP_PASS")
TABLE="$TABLE
"
EXPECTED=$(printf '%s' "$TABLE" | shasum -a 256 | awk '{print $1}')
REMOTE=$(printf '%s' "$TABLE" | ssh "$HOST" '
  set -eu
  doas /usr/bin/install -m 640 -o root -g _smtpd /dev/null /etc/mail/secrets.new
  doas /usr/bin/tee /etc/mail/secrets.new >/dev/null
  doas /bin/sha256 -q /etc/mail/secrets.new
')
if [ "$EXPECTED" != "$REMOTE" ]; then
  ssh "$HOST" 'doas /bin/rm -f /etc/mail/secrets.new' >/dev/null 2>&1 || true
  echo "ERROR: relay credential transport verification failed; live file unchanged" >&2
  exit 1
fi
ssh "$HOST" 'doas /bin/mv -f /etc/mail/secrets.new /etc/mail/secrets'
unset TABLE SMTP_USER SMTP_PASS EXPECTED REMOTE
printf '%s\n' 'RELAY-SECRETS-INSTALLED'
