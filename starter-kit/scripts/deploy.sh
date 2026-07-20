#!/bin/sh
# Deploy an already-rendered config tree to a bootstrapped OpenBSD mail host.
# This script assumes the initial operator/doas bootstrap has been verified.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PUBLIC_CONFIG="${ANE_PUBLIC_CONFIG:-$ROOT/config/public.env}"
RENDERED="${ANE_RENDERED:-$ROOT/rendered}"
[ -r "$PUBLIC_CONFIG" ] && [ -d "$RENDERED/etc" ] || { echo "ERROR: render the starter first" >&2; exit 1; }
MAIL_USER=$(awk -F= '$1 == "MAIL_USER" { print substr($0, 11) }' "$PUBLIC_CONFIG")
MAIL_HOST=$(awk -F= '$1 == "MAIL_HOST" { print substr($0, 11) }' "$PUBLIC_CONFIG")
HOST="${MAIL_USER}@${1:-$MAIL_HOST}"

rsync -av --delete "$RENDERED/etc/" "$HOST":~/etc-staging/
rsync -av "$ROOT/scripts/merge-aliases.sh" "$HOST":~/merge-aliases.sh
ssh "$HOST" '
  set -eu
  USER_HOME=$HOME

  /usr/bin/doas -C "$USER_HOME/etc-staging/doas.conf"
  doas /bin/cp -R "$USER_HOME/etc-staging/doas.conf" /etc/doas.conf

  doas /usr/sbin/httpd -n -f "$USER_HOME/etc-staging/httpd.conf"
  doas /sbin/pfctl -nf "$USER_HOME/etc-staging/pf.conf"
  doas /usr/sbin/smtpd -n -f "$USER_HOME/etc-staging/mail/smtpd.conf"

  set -- /etc/rc.d/php*_fpm
  [ "$#" -eq 1 ] && [ -x "$1" ] || {
    printf "%s\n" "ERROR: expected exactly one executable PHP-FPM service" >&2
    exit 1
  }
  PHP_FPM=$(basename "$1")
  /usr/sbin/rcctl check "$PHP_FPM"

  "$USER_HOME/merge-aliases.sh" /etc/mail/aliases "$USER_HOME/etc-staging/mail/aliases.local" "$USER_HOME/etc-staging/aliases.merged"
  /usr/bin/sed "s|table aliases file:/etc/mail/aliases|table aliases file:$USER_HOME/etc-staging/aliases.merged|" "$USER_HOME/etc-staging/mail/smtpd.conf" > "$USER_HOME/etc-staging/smtpd.conf.alias-check"
  doas /usr/sbin/smtpd -n -f "$USER_HOME/etc-staging/smtpd.conf.alias-check"

  doas /bin/cp -R "$USER_HOME/etc-staging/acme-client.conf" /etc/acme-client.conf
  doas /bin/cp -R "$USER_HOME/etc-staging/httpd.conf" /etc/httpd.conf
  doas /bin/cp -R "$USER_HOME/etc-staging/pf.conf" /etc/pf.conf
  doas /bin/cp -R "$USER_HOME/etc-staging/mail/." /etc/mail/
  doas /bin/cp -R "$USER_HOME/etc-staging/dovecot/." /etc/dovecot/
  doas /bin/cp -R "$USER_HOME/etc-staging/ssh/." /etc/ssh/
  doas /usr/sbin/chown -R root:wheel /etc/doas.conf /etc/pf.conf /etc/httpd.conf /etc/acme-client.conf /etc/mail /etc/dovecot /etc/ssh
  doas /usr/sbin/chown -R _dkimsign /etc/mail/dkim
  doas /bin/chmod 640 /etc/mail/secrets
  doas /usr/sbin/chown root:_smtpd /etc/mail/secrets

  doas /bin/cp "$USER_HOME/etc-staging/aliases.merged" /etc/mail/aliases.new
  doas /bin/chmod 644 /etc/mail/aliases.new
  doas /usr/sbin/chown root:wheel /etc/mail/aliases.new
  doas /bin/mv -f /etc/mail/aliases.new /etc/mail/aliases

  doas /usr/sbin/smtpd -n
  doas /usr/sbin/httpd -n
  doas /sbin/pfctl -nf /etc/pf.conf
  doas /sbin/pfctl -f /etc/pf.conf
  doas /usr/sbin/rcctl restart smtpd
  doas /usr/sbin/rcctl restart dovecot
  doas /usr/sbin/rcctl restart httpd
  printf "%s\n" DEPLOY-OK
'
