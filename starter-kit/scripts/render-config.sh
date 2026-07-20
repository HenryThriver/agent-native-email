#!/bin/sh
# Validate public inputs and render the OpenBSD config tree.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
CONFIG="${1:-$ROOT/config/public.env}"
OUTPUT="${2:-$ROOT/rendered}"

[ -r "$CONFIG" ] || { echo "ERROR: missing public config: $CONFIG" >&2; exit 1; }
[ ! -e "$OUTPUT" ] || { echo "ERROR: output already exists: $OUTPUT" >&2; exit 1; }

ALLOWED='DOMAIN MAIL_HOST MAIL_USER DKIM_SELECTOR RELAY_HOST RELAY_PORT OUTBOUND_MODE VULTR_REGION VULTR_PLAN'
for KEY in $ALLOWED; do
  COUNT=$(awk -F= -v key="$KEY" '$1 == key { count++ } END { print count+0 }' "$CONFIG")
  [ "$COUNT" -eq 1 ] || { echo "ERROR: $KEY must appear exactly once" >&2; exit 1; }
done

while IFS= read -r LINE || [ -n "$LINE" ]; do
  case "$LINE" in ''|'#'*) continue ;; esac
  KEY=${LINE%%=*}
  case " $ALLOWED " in *" $KEY "*) ;; *) echo "ERROR: unknown or malformed config line" >&2; exit 1 ;; esac
done < "$CONFIG"

value() { awk -F= -v key="$1" '$1 == key { print substr($0, length(key)+2) }' "$CONFIG"; }
DOMAIN=$(value DOMAIN)
MAIL_HOST=$(value MAIL_HOST)
MAIL_USER=$(value MAIL_USER)
DKIM_SELECTOR=$(value DKIM_SELECTOR)
RELAY_HOST=$(value RELAY_HOST)
RELAY_PORT=$(value RELAY_PORT)
OUTBOUND_MODE=$(value OUTBOUND_MODE)
VULTR_REGION=$(value VULTR_REGION)
VULTR_PLAN=$(value VULTR_PLAN)

valid_dns_name() {
  NAME="$1"
  [ -n "$NAME" ] && [ "${#NAME}" -le 253 ] || return 1
  case "$NAME" in *[!a-z0-9.-]*|.*|*.|*..*|*-.*|*.-*) return 1 ;; esac
  case "$NAME" in *.*) return 0 ;; *) return 1 ;; esac
}

valid_dns_name "$DOMAIN" || { echo "ERROR: invalid DOMAIN" >&2; exit 1; }
valid_dns_name "$MAIL_HOST" || { echo "ERROR: invalid MAIL_HOST" >&2; exit 1; }
[ "$MAIL_HOST" = "mail.$DOMAIN" ] || { echo "ERROR: v1 requires MAIL_HOST=mail.DOMAIN" >&2; exit 1; }
printf '%s' "$MAIL_USER" | grep -Eq '^[a-z_][a-z0-9_-]{0,30}$' || { echo "ERROR: invalid MAIL_USER" >&2; exit 1; }
printf '%s' "$DKIM_SELECTOR" | grep -Eq '^[a-z0-9][a-z0-9-]{0,62}$' || { echo "ERROR: invalid DKIM_SELECTOR" >&2; exit 1; }
valid_dns_name "$RELAY_HOST" || { echo "ERROR: invalid RELAY_HOST" >&2; exit 1; }
printf '%s' "$RELAY_PORT" | grep -Eq '^[0-9]{2,5}$' || { echo "ERROR: invalid RELAY_PORT" >&2; exit 1; }
[ "$RELAY_PORT" -ge 1 ] && [ "$RELAY_PORT" -le 65535 ] || { echo "ERROR: RELAY_PORT out of range" >&2; exit 1; }
case "$OUTBOUND_MODE" in auto|relay) ;; *) echo "ERROR: OUTBOUND_MODE must be auto or relay; use the gated selector for direct" >&2; exit 1 ;; esac
printf '%s' "$VULTR_REGION" | grep -Eq '^[a-z0-9-]+$' || { echo "ERROR: invalid VULTR_REGION" >&2; exit 1; }
printf '%s' "$VULTR_PLAN" | grep -Eq '^[a-z0-9-]+$' || { echo "ERROR: invalid VULTR_PLAN" >&2; exit 1; }

mkdir -p "$OUTPUT"
find "$ROOT/templates" -type f -name '*.tmpl' | while IFS= read -r TEMPLATE; do
  REL=${TEMPLATE#"$ROOT/templates/"}
  DEST="$OUTPUT/${REL%.tmpl}"
  mkdir -p "$(dirname "$DEST")"
  sed \
    -e "s|__DOMAIN__|$DOMAIN|g" \
    -e "s|__MAIL_HOST__|$MAIL_HOST|g" \
    -e "s|__MAIL_USER__|$MAIL_USER|g" \
    -e "s|__DKIM_SELECTOR__|$DKIM_SELECTOR|g" \
    -e "s|__RELAY_HOST__|$RELAY_HOST|g" \
    -e "s|__RELAY_PORT__|$RELAY_PORT|g" \
    "$TEMPLATE" > "$DEST"
done

# Both outbound paths are always rendered. Auto starts on the relay so sending
# works immediately; direct becomes active only after its explicit gate passes.
cp "$OUTPUT/etc/mail/smtpd.conf.relay" "$OUTPUT/etc/mail/smtpd.conf"

if grep -R -E '__[A-Z0-9_]+__' "$OUTPUT" >/dev/null 2>&1; then
  echo "ERROR: unresolved template placeholder" >&2
  exit 1
fi

printf '%s\n' "RENDER-OK $OUTPUT"
