# Walkthrough — Heartbeat health check green, but is it actually logging?

> ⚠️ **SPOILERS.** Work the incident from `ticket.md` first.

<details>
<summary>Hint 1 — Where to look first</summary>

Same instinct as before: don't trust the health check, verify the actual
output directly.

```
docker exec -it abhyas-legacy-vm bash
tail -f /var/log/heartbeat/heartbeat.log
```

</details>

<details>
<summary>Hint 2 — Narrowing it down</summary>

If it's stale but `curl localhost:8080/health` still returns `200` and
`systemctl status` says `active`, you've seen this exact shape of failure
before (`INC-heartbeat-disk-full`) — a background thread died while the
main thread stayed up. Same symptom, but the ticket says this time it's
tied to a permissions change, not disk space. Check the journal and the
actual file permissions:

```
journalctl -u heartbeat -n 20 --no-pager
ls -l /var/log/heartbeat/
```

</details>

<details>
<summary>Hint 3 — Root cause</summary>

Look closely at *who owns the file* versus *who owns the directory* — a
security hardening pass often changes directory ownership recursively, but
double-check whether the individual file actually got touched too, or only
the directory.

</details>

<details>
<summary>Full investigation path</summary>

1. `tail -f /var/log/heartbeat/heartbeat.log` → nothing new appearing.
2. `journalctl -u heartbeat -n 20 --no-pager` → a traceback from the
   `beat` thread: `PermissionError: [Errno 13] Permission denied:
   '/var/log/heartbeat/heartbeat.log'`.
3. `ls -l /var/log/heartbeat/` → `heartbeat.log` is owned by `root`, not
   `heartbeat` — the service account can no longer write to its own log
   file.

**Resolution:**

```
chown heartbeat:heartbeat /var/log/heartbeat/heartbeat.log
systemctl restart heartbeat
```

**Why the fix needs a restart, not just a `chown`:** the logging thread
already crashed and exited — fixing the permission doesn't resurrect a
dead thread, only a fresh process launch (with the corrected permissions in
place from the start) does. Fixing the cause without restarting the
service is a common half-fix that leaves the incident technically
unresolved.

**Verify:** run `./grade.sh` — like the disk-full scenario, it specifically
checks the log is *still advancing* a few seconds apart, not just that the
health check is green.

</details>
