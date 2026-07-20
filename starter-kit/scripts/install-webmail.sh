#!/bin/sh
# Install and initialize Roundcube on the OpenBSD mail host.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
RENDERED="${ANE_RENDERED:-$ROOT/rendered}"
INSTALL_ROOT=/var/www/roundcubemail
DB_PATH="$INSTALL_ROOT/db/sqlite.db"
CONFIG_PATH="$INSTALL_ROOT/config/config.inc.php"
KEY_PATH="$INSTALL_ROOT/config/.des_key"

[ "$(id -u)" -eq 0 ] || {
	printf '%s\n' "ERROR: run this installer as root on the OpenBSD mail host" >&2
	exit 1
}
[ -r "$RENDERED/etc/roundcubemail/config.inc.php.tpl" ] || {
	printf '%s\n' "ERROR: render the starter before installing webmail" >&2
	exit 1
}

if ! pkg_info -e 'roundcubemail-*' >/dev/null 2>&1; then
	pkg_add roundcubemail
fi

# Refuse to guess when multiple PHP versions are installed. OpenBSD find does
# not support GNU's -quit, so collect the candidates with a shell glob.
set -- /etc/php-*.sample
[ "$#" -eq 1 ] && [ -d "$1" ] || {
	printf '%s\n' "ERROR: expected exactly one /etc/php-*.sample directory" >&2
	exit 1
}
PHP_SAMPLE=$1
PHP_LIVE=${PHP_SAMPLE%.sample}
[ -d "$PHP_LIVE" ] || {
	printf 'ERROR: matching PHP config directory is missing: %s\n' "$PHP_LIVE" >&2
	exit 1
}

for MODULE in intl pdo_sqlite pspell zip; do
	[ -r "$PHP_SAMPLE/$MODULE.ini" ] || {
		printf 'ERROR: required PHP module config is missing: %s\n' "$MODULE" >&2
		exit 1
	}
	install -o root -g wheel -m 644 "$PHP_SAMPLE/$MODULE.ini" "$PHP_LIVE/$MODULE.ini"
done

SQL_INIT="$INSTALL_ROOT/SQL/sqlite.initial.sql"
[ -f "$SQL_INIT" ] || {
	printf '%s\n' "ERROR: Roundcube SQLite schema not found" >&2
	exit 1
}

install -d -o www -g www -m 750 "$INSTALL_ROOT/db"
install -d -o root -g www -m 750 "$INSTALL_ROOT/config"

if [ ! -f "$KEY_PATH" ]; then
	umask 077
	openssl rand -hex 12 > "$KEY_PATH"
	chown www:www "$KEY_PATH"
	chmod 600 "$KEY_PATH"
fi
[ "$(wc -c < "$KEY_PATH" | tr -d ' ')" -eq 25 ] || {
	printf '%s\n' "ERROR: Roundcube DES key must contain 24 characters plus newline" >&2
	exit 1
}

if [ ! -f "$DB_PATH" ]; then
	sqlite3 "$DB_PATH" < "$SQL_INIT"
	chown www:www "$DB_PATH"
	chmod 640 "$DB_PATH"
fi

install -o root -g www -m 640 \
	"$RENDERED/etc/roundcubemail/config.inc.php.tpl" "$CONFIG_PATH"

set -- /etc/rc.d/php*_fpm
[ "$#" -eq 1 ] && [ -x "$1" ] || {
	printf '%s\n' "ERROR: expected exactly one executable PHP-FPM service" >&2
	exit 1
}
SERVICE=$(basename "$1")
rcctl enable "$SERVICE"
rcctl restart "$SERVICE" 2>/dev/null || rcctl start "$SERVICE"

printf '%s\n' "WEBMAIL-INSTALLED"
