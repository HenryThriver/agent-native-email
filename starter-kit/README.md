# Agent-Native Email Starter Kit

**Version:** 0.1.2-experimental  
**Status:** Early public reference; human-supervised use only

This is the sanitized reference core for the Agent-Native Email handoff. It is
deliberately smaller than the live system it was derived from.

Included now:

- validated public configuration and secret-reference examples;
- rendered OpenBSD configs for ACME, firewall, SSH hardening, OpenSMTPD,
  Dovecot, Roundcube webmail, aliases, and least-privilege deployment;
- relay and direct-to-MX outbound candidates, with relay active in `auto` mode
  and a receipt-gated selector for direct delivery;
- atomic relay-secret installation;
- repeat-safe alias merging;
- a resumable phase ledger;
- offline safety and privacy regression tests.

Required before using this starter:

- ownership and DNS control of a domain; without it, stop and complete a
  separate human-approved domain acquisition preflight;

Excluded from the reference build:

- newsletter/contact-form DNS;
- personal website records;
- any real domain, address, IP, provider ID, DNS key, or secret.

`OUTBOUND_MODE=auto` deliberately renders both paths and activates SMTP2GO so
outbound works from launch. Direct-to-MX is the preferred owned path only after
port-25 egress, forward-confirmed PTR, SPF, DKIM, DMARC, deliverability, human
approval, and relay-rollback readiness are all recorded as passing.

## Local draft check

```sh
cp config/public.env.example config/public.env
cp config/secrets.env.tpl.example config/secrets.env.tpl
scripts/check-starter.sh
```

Read the release boundary in the agent guide before deployment. This starter is
derived from a working personal system and passes its offline suite, but the
public end-to-end flow has not been independently replayed from scratch.
