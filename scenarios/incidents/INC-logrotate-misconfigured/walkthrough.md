# Walkthrough — Audit finding: are heartbeat's logs actually being rotated?

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

The stakeholder's comment is the whole clue: "looked fine but silently
weren't doing anything." Don't just check that the config file exists —
check whether it actually does what it claims.

```
docker exec -it abhyas-legacy-vm bash
cat /etc/logrotate.d/heartbeat
```

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

logrotate has a real dry-run mode built for exactly this kind of audit —
use it instead of trying to read the config and reason about it by eye:

```
logrotate -d /etc/logrotate.d/heartbeat
```

Read the "considering log ..." lines closely. Do they match real files
that actually exist on this box?

</details>

<details>
<summary>Full investigation path</summary>

1. `cat /etc/logrotate.d/heartbeat` -> looks completely normal at a
   glance: valid directives, sensible values.
2. `logrotate -d /etc/logrotate.d/heartbeat` -> the "considering log" line
   shows `/var/log/heatbeat/*.log` — missing the "r" in "heartbeat". The
   glob matches zero real files. logrotate doesn't error on this; it just
   silently has nothing to do.
3. `ls /var/log/heartbeat/` -> confirms the real directory (spelled
   correctly) and its log files exist, just not covered by the policy.

Resolution:

```
sed -i 's|/var/log/heatbeat/|/var/log/heartbeat/|' /etc/logrotate.d/heartbeat
logrotate -d /etc/logrotate.d/heartbeat   # confirm it now considers the real files
```

Why this one is worth taking seriously even though nothing is on fire
yet: this is precisely the kind of silent gap that turns into
INC-heartbeat-disk-full later — a policy that looks correct in a review
but was never actually protecting anything. Catching it here, before it
causes an outage, is strictly more valuable than debugging the outage it
would eventually cause.

Verify: run `./grade.sh` — it doesn't just check the config file's
syntax, it runs logrotate's own dry-run and confirms the real files are
actually considered.

</details>
