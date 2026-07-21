# Agent-Native Email

Self-hosted email, built by your coding agent, approved by you at every gate.

I built my own mail server without knowing how email servers work. Three days
in, my domain was receiving mail on a tiny OpenBSD box I control and sending
properly authenticated mail through a relay. Soon after: webmail, a local
searchable mirror, a tested restore path, and a propose-only agent sorting new
messages into a daily brief. (I still can't explain DKIM without a cheat
sheet. The server doesn't mind.)

I didn't become an infrastructure engineer to get there. I learned how to give
an agent enough context, authority, tests, and stopping rules to build it with
me. This repo is that handoff, packaged so your agent can do the same for you.

It's one artifact of my [agent-native email quest](https://thrivinghenry.com/quests/agent-native-email),
a build-in-public project at [ThrivingHenry](https://thrivinghenry.com). The
[intro essay](https://thrivinghenry.com/writing/agent-native-email) has the
story and the why.

## Just run this

Copy the prompt below into Claude Code, Codex, or any capable coding agent.

> Help me build agent-native, self-hosted email. Read
> https://raw.githubusercontent.com/HenryThriver/agent-native-email/v0.1.0-experimental/agent-native-email.md
> and start in PREFLIGHT mode. This is an experimental guide. Do not change
> anything, create paid resources, or ask me to paste secrets into chat until
> you have inspected what you safely can and shown me the architecture, cost,
> risks, support boundary, and exact approval gates. Confirm that I own and
> control a domain before beginning infrastructure work. Then follow the guide
> phase by phase, preserve receipts, and stop at every named human gate.

You answer at most eight questions up front. Your agent then works toward a
verified, ready-to-cut-over mailbox, showing exact prices before it creates
anything billable. Nothing touches your DNS, sends mail, or spends money
without your explicit approval.

## What you end up with

- a mail server you own: OpenSMTPD inbound, Dovecot IMAPS, a default-deny pf
  firewall, acme-client TLS, and Roundcube webmail on a small OpenBSD VPS
- outbound that works from day one: SMTP2GO relay first, direct-to-MX only
  after its deliverability gates pass, with the relay kept ready as a tested
  rollback
- SPF, DKIM, and DMARC that actually align
- a local Maildir mirror (mbsync + notmuch), ready for a propose-only inbox
  agent with no ability to send
- receipts, rollback plans, and a resumable ledger for every phase

## What's in this repo

| File | What it is |
|---|---|
| [`agent-native-email.md`](agent-native-email.md) | The single file your agent follows |
| [`starter-kit/`](starter-kit/) | Tested configs, scripts, and templates the guide builds from |
| [`STARTER-KIT-CONTRACT.md`](STARTER-KIT-CONTRACT.md) | The interface between guide and starter |
| [`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md) | What experimental means, and the bar for stable v1 |
| [`SUPPORT.md`](SUPPORT.md) | Best-effort help, and how to ask for it safely |
| [`LICENSE`](LICENSE) | MIT |

Everything here was extracted from the live system running my actual mailbox,
then sanitized and re-tested. The starter's offline suite scans for leaked
identifiers on every run, and I fingerprint-scanned the full git history
before the first push.

## Before you start

You need a domain you own and control: registrar access, authoritative DNS,
and a recovery channel that doesn't depend on the new mailbox. No domain yet?
The guide runs a separate acquisition preflight before touching any
infrastructure. The domain is the durable part of an email address -
everything else is a swappable part (h/t [Derek Sivers](https://sive.rs/ti)).

You'll also want about ten minutes for kickoff questions, plus a budget for a
small VPS and a relay account. Exact prices appear at the first gate, before
anything exists to pay for.

## Experimental, and honest about it

This is `v0.1.0-experimental`. The architecture runs my real email every day,
and the starter passes its offline safety suite. What it hasn't had yet: a
from-scratch replay by someone who isn't me.

So, during the experimental period:

- prefer a fresh or non-critical domain
- keep your current provider until the new mailbox has earned your trust
- expect your agent to stop at every named human gate - silence is not approval

The [release checklist](RELEASE-CHECKLIST.md) tracks the road to stable v1:
provider adapters, fresh-domain and migration rehearsals, and independent
security review.

## Follow the build

The quest keeps going, and the next guides get written the same way this one
was. [Follow along](https://thrivinghenry.com/quests/agent-native-email) or
[join the newsletter](https://thrivinghenry.com/join).

Let's get Thriving. ~h
