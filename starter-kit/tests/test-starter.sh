#!/bin/bash
set -euo pipefail
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
SCRATCH="$($ROOT/scripts/safe-scratch.sh create startertest)"
cleanup() { "$ROOT/scripts/safe-scratch.sh" cleanup "$SCRATCH"; }
trap cleanup EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

for SCRIPT in "$ROOT"/scripts/*.sh; do
  bash -n "$SCRIPT" || fail "syntax: $SCRIPT"
done

# Public checks must remain generic. Private production fingerprints belong in
# the source repository's pre-publish scanner and must never ship here.
IP_LIST=$(grep -RhoE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$ROOT" | sort -u || true)
while IFS= read -r IP; do
  [ -n "$IP" ] || continue
  case "$IP" in
    127.0.0.1|127.0.0.2|127.0.0.4|2.0.0.127|11.113.0.203|203.0.113.10|203.0.113.11) ;;
    *) fail "non-example IPv4 address found in public starter" ;;
  esac
done <<< "$IP_LIST"
if find "$ROOT" -type f \( -name '*.key' -o -name '*.pem' -o -name secrets -o -name '.env' \) | grep . >/dev/null 2>&1; then
  fail "secret-shaped file found in public starter"
fi
grep -Ev '^[A-Z0-9_]+=op://[^[:space:]]+$|^#|^$' "$ROOT/config/secrets.env.tpl.example" | grep . >/dev/null 2>&1 && fail "secret manifest contains a raw or malformed value"

if "$ROOT/scripts/preflight.sh" "$ROOT/config/public.env.example" >"$SCRATCH/preflight-example.out" 2>&1; then
  fail "preflight accepted the example domain"
fi
grep -q 'DOMAIN-OWNERSHIP-REQUIRED' "$SCRATCH/preflight-example.out" || fail "preflight did not explain the domain prerequisite"

cp "$ROOT/config/public.env.example" "$SCRATCH/public.env"
"$ROOT/scripts/render-config.sh" "$SCRATCH/public.env" "$SCRATCH/rendered" >/dev/null
! grep -R -E '__[A-Z0-9_]+__' "$SCRATCH/rendered" >/dev/null || fail "render left a placeholder"
grep -q 'mail.example.com' "$SCRATCH/rendered/etc/mail/smtpd.conf" || fail "render missed mail host"
grep -q 'smtp+tls://smtp2go@mail.smtp2go.com:2525' "$SCRATCH/rendered/etc/mail/smtpd.conf" || fail "relay-first default missing"
grep -q '^action "local_mail" maildir junk alias <aliases>$' "$SCRATCH/rendered/etc/mail/smtpd.conf" || fail "alias-safe Maildir default missing"
! grep -q 'relay helo' "$SCRATCH/rendered/etc/mail/smtpd.conf" || fail "direct outbound leaked into default"
cmp "$SCRATCH/rendered/etc/mail/smtpd.conf" "$SCRATCH/rendered/etc/mail/smtpd.conf.relay" >/dev/null || fail "auto mode did not activate relay"
grep -q 'action "outbound" relay helo' "$SCRATCH/rendered/etc/mail/smtpd.conf.direct" || fail "direct candidate missing"
grep -q 'listen on \* tls port 443' "$SCRATCH/rendered/etc/httpd.conf" || fail "webmail HTTPS listener missing"
grep -q 'port { 22 25 80 443 587 993 }' "$SCRATCH/rendered/etc/pf.conf" || fail "webmail HTTPS firewall rule missing"
grep -q 'root "/roundcubemail/public_html"' "$SCRATCH/rendered/etc/httpd.conf" || fail "Roundcube web root missing"
grep -q "imap_host.*127.0.0.1:993" "$SCRATCH/rendered/etc/roundcubemail/config.inc.php.tpl" || fail "Roundcube IMAP path missing"
grep -q "smtp_host.*127.0.0.1:587" "$SCRATCH/rendered/etc/roundcubemail/config.inc.php.tpl" || fail "Roundcube SMTP path missing"
grep -q "strlen(\$des_key) !== 24" "$SCRATCH/rendered/etc/roundcubemail/config.inc.php.tpl" || fail "Roundcube DES key validation missing"
! grep -q 'php-8\.3' "$ROOT/scripts/install-webmail.sh" || fail "webmail installer hardcodes a PHP version"
grep -q 'port submission tls-require.* auth filter "dkim"' "$SCRATCH/rendered/etc/mail/smtpd.conf" || fail "submission is not TLS/auth/DKIM gated"

"$ROOT/scripts/check-webmail.sh" --body-file "$ROOT/tests/fixtures/webmail-login.html" >/dev/null || fail "valid webmail login fixture failed"
if "$ROOT/scripts/check-webmail.sh" --body-file "$ROOT/tests/fixtures/webmail-error.html" >/dev/null 2>&1; then
  fail "webmail checker accepted Roundcube error page"
fi

if "$ROOT/scripts/select-outbound.sh" direct "$SCRATCH/missing-receipt.json" "$SCRATCH/rendered" >/dev/null 2>&1; then
  fail "direct outbound activated without a gate receipt"
fi
printf '%s\n' '{"schema_version":1,"human_approved":false,"port25_egress":true,"ptr_fcrdns":true,"spf_aligned":true,"dkim_aligned":true,"dmarc_aligned":true,"deliverability_passed":true,"rollback_relay_ready":true}' > "$SCRATCH/direct-gate-invalid.json"
if "$ROOT/scripts/select-outbound.sh" direct "$SCRATCH/direct-gate-invalid.json" "$SCRATCH/rendered" >/dev/null 2>&1; then
  fail "direct outbound activated without human approval"
fi
printf '%s\n' '{"schema_version":1,"human_approved":true,"port25_egress":true,"ptr_fcrdns":true,"spf_aligned":true,"dkim_aligned":true,"dmarc_aligned":true,"deliverability_passed":true,"rollback_relay_ready":true}' > "$SCRATCH/direct-gate-valid.json"
"$ROOT/scripts/select-outbound.sh" direct "$SCRATCH/direct-gate-valid.json" "$SCRATCH/rendered" >/dev/null
cmp "$SCRATCH/rendered/etc/mail/smtpd.conf" "$SCRATCH/rendered/etc/mail/smtpd.conf.direct" >/dev/null || fail "direct selector did not activate direct candidate"
"$ROOT/scripts/select-outbound.sh" relay ignored "$SCRATCH/rendered" >/dev/null
cmp "$SCRATCH/rendered/etc/mail/smtpd.conf" "$SCRATCH/rendered/etc/mail/smtpd.conf.relay" >/dev/null || fail "relay fallback did not restore relay candidate"

cp "$SCRATCH/public.env" "$SCRATCH/invalid.env"
sed -i.bak 's/^DOMAIN=.*/DOMAIN=bad;domain/' "$SCRATCH/invalid.env"
if "$ROOT/scripts/render-config.sh" "$SCRATCH/invalid.env" "$SCRATCH/invalid-render" >/dev/null 2>&1; then
  fail "renderer accepted shell-shaped domain input"
fi
cp "$SCRATCH/public.env" "$SCRATCH/direct-bypass.env"
sed -i.bak 's/^OUTBOUND_MODE=.*/OUTBOUND_MODE=direct/' "$SCRATCH/direct-bypass.env"
if "$ROOT/scripts/render-config.sh" "$SCRATCH/direct-bypass.env" "$SCRATCH/direct-bypass-render" >/dev/null 2>&1; then
  fail "renderer bypassed the direct-send receipt gate"
fi

cat > "$SCRATCH/aliases.base" <<'EOF'
root: operator-choice
custom: preserved
EOF
cat > "$SCRATCH/aliases.managed" <<'EOF'
root: owner
dmarc: owner
EOF
"$ROOT/scripts/merge-aliases.sh" "$SCRATCH/aliases.base" "$SCRATCH/aliases.managed" "$SCRATCH/aliases.once"
grep -qx 'root: operator-choice' "$SCRATCH/aliases.once" || fail "alias merge overwrote operator choice"
grep -qx 'custom: preserved' "$SCRATCH/aliases.once" || fail "alias merge lost operator alias"
[ "$(grep -c '^dmarc:' "$SCRATCH/aliases.once")" -eq 1 ] || fail "managed alias not added exactly once"
"$ROOT/scripts/merge-aliases.sh" "$SCRATCH/aliases.once" "$SCRATCH/aliases.managed" "$SCRATCH/aliases.twice"
cmp "$SCRATCH/aliases.once" "$SCRATCH/aliases.twice" >/dev/null || fail "alias merge is not repeat-safe"

cat > "$SCRATCH/mock-dig" <<'EOF'
#!/bin/sh
NAME="$2"
case "$NAME" in
  2.0.0.127.*) printf '%s\n' 127.0.0.2 ;;
  11.113.0.203.*) printf '%s\n' 127.0.0.4 ;;
esac
EOF
chmod +x "$SCRATCH/mock-dig"
DNSBL_DIG="$SCRATCH/mock-dig" "$ROOT/scripts/dnsbl-check.sh" --self-test >/dev/null || fail "DNSBL self-test did not prove the checker"
DNSBL_DIG="$SCRATCH/mock-dig" "$ROOT/scripts/dnsbl-check.sh" 203.0.113.10 >/dev/null || fail "clean fixture was not clean"
set +e
DNSBL_DIG="$SCRATCH/mock-dig" "$ROOT/scripts/dnsbl-check.sh" 203.0.113.11 >/dev/null
DNSBL_STATUS=$?
set -e
[ "$DNSBL_STATUS" -eq 1 ] || fail "listed fixture was not listed"

"$ROOT/scripts/init-ledger.sh" fresh "$SCRATCH/ledger.json" >/dev/null
jq -e '.guide_version=="0.1.0-experimental" and .mode=="fresh" and (.phases|length)==8' "$SCRATCH/ledger.json" >/dev/null || fail "ledger schema invalid"
printf '%s\n' 'privacy-safe receipt' > "$SCRATCH/preflight.txt"
"$ROOT/scripts/record-phase.sh" preflight completed "$SCRATCH/preflight.txt" "$SCRATCH/ledger.json" >/dev/null
jq -e '.phases[] | select(.key=="preflight") | .status=="completed" and (.receipts|length)==1' "$SCRATCH/ledger.json" >/dev/null || fail "phase receipt missing"
if "$ROOT/scripts/record-phase.sh" preflight blocked "$SCRATCH/preflight.txt" "$SCRATCH/ledger.json" >/dev/null 2>&1; then
  fail "completed phase was allowed to regress"
fi

grep -q 'doas -C' "$ROOT/scripts/deploy.sh" || fail "staged doas validation missing"
grep -q 'smtpd -n -f' "$ROOT/scripts/deploy.sh" || fail "staged smtp validation missing"
grep -q 'rcctl check.*PHP_FPM' "$ROOT/scripts/deploy.sh" || fail "PHP-FPM readiness check missing"
! grep -q 'doas .*rcctl .*PHP_FPM' "$ROOT/scripts/deploy.sh" || fail "deploy requires ungranted dynamic PHP-FPM doas authority"
grep -q 'chown -R _dkimsign /etc/mail/dkim' "$ROOT/scripts/deploy.sh" || fail "DKIM ownership reset missing"
grep -q '/etc/mail/secrets.new' "$ROOT/scripts/install-relay-secrets.sh" || fail "atomic relay temp path missing"
grep -q 'shasum -a 256' "$ROOT/scripts/install-relay-secrets.sh" || fail "relay transport digest missing"

line_of() { grep -n -m1 "$1" "$2" | cut -d: -f1; }
DOAS_CHECK=$(line_of 'doas -C' "$ROOT/scripts/deploy.sh")
DOAS_COPY=$(line_of 'etc-staging/doas.conf.* /etc/doas.conf' "$ROOT/scripts/deploy.sh")
SMTP_STAGE=$(line_of 'smtpd -n -f.*etc-staging/mail/smtpd.conf' "$ROOT/scripts/deploy.sh")
MAIL_COPY=$(line_of 'etc-staging/mail/.* /etc/mail/' "$ROOT/scripts/deploy.sh")
GENERAL_OWNER=$(line_of 'chown -R root:wheel' "$ROOT/scripts/deploy.sh")
DKIM_OWNER=$(line_of 'chown -R _dkimsign' "$ROOT/scripts/deploy.sh")
ALIAS_INSTALL=$(line_of 'aliases.merged.* /etc/mail/aliases.new' "$ROOT/scripts/deploy.sh")
FINAL_SMTP=$(line_of 'doas /usr/sbin/smtpd -n$' "$ROOT/scripts/deploy.sh")
[ "$DOAS_CHECK" -lt "$DOAS_COPY" ] || fail "doas policy copied before validation"
[ "$SMTP_STAGE" -lt "$MAIL_COPY" ] || fail "mail config copied before staged validation"
[ "$DKIM_OWNER" -gt "$GENERAL_OWNER" ] || fail "DKIM ownership not restored after general ownership"
[ "$ALIAS_INSTALL" -lt "$FINAL_SMTP" ] || fail "aliases installed after final SMTP validation"

mkdir -p "$SCRATCH/bin" "$SCRATCH/remote"
cat > "$SCRATCH/bin/ssh" <<'EOF'
#!/bin/sh
if env | grep -q '^SMTP2GO_'; then
  echo "relay secret leaked into ssh environment" >&2
  exit 91
fi
COMMAND="$*"
case "$COMMAND" in
  *'/bin/sha256 -q /etc/mail/secrets.new'*)
    cat > "$FAKE_REMOTE/secrets.new"
    if [ "${FAIL_AFTER_WRITE:-0}" = 1 ]; then
      printf '%064d\n' 0
    else
      shasum -a 256 "$FAKE_REMOTE/secrets.new" | awk '{print $1}'
    fi
    ;;
  *'/bin/mv -f /etc/mail/secrets.new /etc/mail/secrets'*)
    mv "$FAKE_REMOTE/secrets.new" "$FAKE_REMOTE/secrets"
    ;;
  *'/bin/rm -f /etc/mail/secrets.new'*)
    rm -f "$FAKE_REMOTE/secrets.new"
    ;;
  *) cat >/dev/null ;;
esac
EOF
chmod +x "$SCRATCH/bin/ssh"
printf '%s\n' 'smtp2go old-user:old-pass' > "$SCRATCH/remote/secrets"
if PATH="$SCRATCH/bin:$PATH" FAKE_REMOTE="$SCRATCH/remote" FAIL_AFTER_WRITE=1 \
  ANE_PUBLIC_CONFIG="$SCRATCH/public.env" \
  SMTP2GO_USERNAME=test-user SMTP2GO_PASSWORD=test-pass \
  "$ROOT/scripts/install-relay-secrets.sh" test-host >/dev/null 2>&1; then
  fail "failure injection replaced relay credentials"
fi
[ "$(cat "$SCRATCH/remote/secrets")" = 'smtp2go old-user:old-pass' ] || fail "failed relay rotation changed live file"
[ ! -e "$SCRATCH/remote/secrets.new" ] || fail "failed relay rotation left temp file"
OUT=$(PATH="$SCRATCH/bin:$PATH" FAKE_REMOTE="$SCRATCH/remote" \
  ANE_PUBLIC_CONFIG="$SCRATCH/public.env" \
  SMTP2GO_USERNAME=test-user SMTP2GO_PASSWORD=test-pass \
  "$ROOT/scripts/install-relay-secrets.sh" test-host)
[ "$OUT" = 'RELAY-SECRETS-INSTALLED' ] || fail "relay installer emitted unexpected output"
[ "$(cat "$SCRATCH/remote/secrets")" = 'smtp2go test-user:test-pass' ] || fail "relay table malformed"
if PATH="$SCRATCH/bin:$PATH" FAKE_REMOTE="$SCRATCH/remote" \
  ANE_PUBLIC_CONFIG="$SCRATCH/public.env" \
  SMTP2GO_USERNAME='bad:user' SMTP2GO_PASSWORD=test-pass \
  "$ROOT/scripts/install-relay-secrets.sh" test-host >/dev/null 2>&1; then
  fail "relay installer accepted invalid username"
fi

grep -q 'OP_LOAD_DESKTOP_APP_SETTINGS=false' "$ROOT/scripts/op-service-account.sh" || fail "1Password desktop integration not disabled"
grep -q 'OP_BIOMETRIC_UNLOCK_ENABLED=false' "$ROOT/scripts/op-service-account.sh" || fail "1Password biometric integration not disabled"
grep -q 'OP_CACHE=false' "$ROOT/scripts/op-service-account.sh" || fail "1Password cache not disabled"

printf '%s\n' 'STARTER-TESTS-OK'
