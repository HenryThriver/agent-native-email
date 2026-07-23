# Starter-Kit Contract

**Version:** 0.1.2-experimental  
**Status:** Early public interface; human-supervised use only

The public guide may rely only on the interfaces in this document. Personal
artifacts from the original build are not part of the contract.

## Supported reference target

- Operator: macOS
- Server: current supported OpenBSD release available from Vultr
- DNS: Cloudflare, authoritative and DNS-only for mail records
- Inbound: OpenSMTPD
- Mail access: Dovecot IMAPS
- Webmail: Roundcube over HTTPS, using the same Dovecot/OpenSMTPD paths
- Outbound: direct-to-MX when its deliverability gate passes; SMTP2GO on port
  2525 is the initial active path and always-ready fallback, with DKIM applied
  before either path
- Local mirror/index: mbsync + notmuch
- Secrets: 1Password CLI service account with a dedicated vault
- Configuration ledger: Git; remote forge optional

## Public configuration

`config/public.env` contains only validated, non-secret values:

- `DOMAIN`
- `MAIL_HOST` (must equal `mail.$DOMAIN` in v1)
- `MAIL_USER`
- `DKIM_SELECTOR`
- `RELAY_HOST`
- `RELAY_PORT`
- `OUTBOUND_MODE` (`auto` or `relay`; both activate relay initially, and direct
  can be activated only through the receipt-gated selector)
- `VULTR_REGION`
- `VULTR_PLAN`

`config/secrets.env.tpl` contains only `op://` references. Raw values never
belong in the repository, command arguments, logs, evidence, or agent chat.

## Required commands

| Command | Contract |
|---|---|
| `scripts/preflight.sh` | Read-only capability and current-DNS inventory; no account or infrastructure mutation |
| `scripts/render-config.sh [config] [output]` | Validate public inputs and render the OpenBSD config tree; unresolved placeholders fail |
| `scripts/dnsbl-check.sh --self-test` | Prove configured reputation sources answer the known-listed test before checking a candidate IP |
| `scripts/init-ledger.sh MODE [path]` | Create a resumable fresh/migration phase ledger without overwriting existing state |
| `scripts/record-phase.sh PHASE STATUS RECEIPT [path]` | Atomically record a phase transition and receipt digest |
| `scripts/merge-aliases.sh BASE MANAGED OUTPUT` | Preserve operator aliases and append only missing valid managed keys |
| `scripts/install-relay-secrets.sh [host]` | Install the relay table via stdin, verify its digest, then atomically replace it |
| `scripts/install-webmail.sh` | On the OpenBSD host, discover the installed PHP version, install/init Roundcube, generate its local key, and start PHP-FPM |
| `scripts/check-webmail.sh [url]` | Require the real Roundcube login surface and protected-config 404; reject HTTP-200 internal-error pages |
| `scripts/select-outbound.sh MODE [receipt] [rendered]` | Atomically select relay, or select direct only after every field in the human-approved gate receipt passes |
| `scripts/deploy.sh [host]` | Stage, validate, install with explicit ownership, validate live config, then restart services |
| `scripts/check-starter.sh` | Run the complete offline starter safety suite |

Provider provisioning, DNS planning/application, DKIM-key creation, server
bootstrap, package installation, client configuration, and acceptance probes are
required for stable v1 but are not yet pinned interfaces in the experimental
release. An agent may implement them from current official APIs only after the
guide's human gates; it must preserve receipts and stop rather than guess.

## Safety properties

1. Rendered defaults expose only SSH, SMTP, ACME HTTP, HTTPS webmail,
   submission, and IMAPS.
2. Both outbound candidates are rendered. `auto` activates the relay so sending
   works immediately; direct activation requires a complete gate receipt and
   retains the relay as the tested rollback.
3. SMTP submission requires TLS and authentication.
4. Inbound mail is accepted only for the configured domains.
5. Unauthenticated relay is structurally absent.
6. Mail aliases use OpenSMTPD's alias-safe default `~/Maildir` delivery.
7. Deployment validates staged configs before touching live network services.
8. Sensitive file ownership is reasserted after every deploy.
9. State transitions are atomic and resumable.
10. Webmail installation discovers the package-owned PHP version and behaviorally
    verifies the login surface rather than trusting HTTP status alone.
11. The distributable `starter-kit/` must contain no personal domain, address,
    IP, provider ID, private key material, or vault name. Repository-level
    attribution and support files may contain the intentionally published author
    name and contact address; those are not starter configuration.
12. Unattended deploy authority is explicit, not hidden: the doas template's
    nopass rules are the operator key's full production authority, and they
    include installing an updated doas policy during a deploy. Possession of
    the operator SSH key must therefore be treated as root on the mail host.
    Narrowing this authority is a stable-v1 work item.
