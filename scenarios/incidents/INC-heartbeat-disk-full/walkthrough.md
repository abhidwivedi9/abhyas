# Walkthrough — Heartbeat health check green, but on-call suspects it's actually stuck

> ⚠️ **SPOILERS.** Work the incident from `ticket.md` first.

<details>
<summary>Hint 1 — Where to look first</summary>

The ticket already tells you the naive check (`/health` or `systemctl
status`) says everything's fine — so don't trust it, verify the actual
signal the stakeholder is worried about:

```
docker exec -it abhyas-legacy-vm bash
tail -f /var/log/heartbeat/heartbeat.log
```

Watch it for 5-10 seconds. Is it actually growing?

</details>

<details>
<summary>Hint 2 — Narrowing it down</summary>

If the log genuinely isn't growing, something inside the process is failing
silently — but `systemctl status` says `active (running)`, and `curl
localhost:8080/health` returns `200`. That combination (main service "up",
but a specific piece of its work has stopped) means part of the process
died without taking the whole thing down with it. Check the process's own
task/thread count and its full journal:

```
systemctl status heartbeat | grep Tasks
journalctl -u heartbeat -n 30 --no-pager
```

</details>

<details>
<summary>Hint 3 — Root cause</summary>

The journal has a traceback, but it's not on the main path that handles
`/health` — it's in a background thread. Read the actual exception, then
check what it's complaining about at the OS level:

```
df -h /var/log/heartbeat
```

</details>

<details>
<summary>Full investigation path</summary>

1. `tail -f /var/log/heartbeat/heartbeat.log` → no new lines appearing,
   despite the service reporting healthy.
2. `systemctl status heartbeat | grep Tasks` → shows `Tasks: 1`, not the
   normal `2` — one of the service's threads is gone.
3. `journalctl -u heartbeat -n 30 --no-pager` → a traceback from the
   *logging* thread (not the HTTP handler): `OSError: [Errno 28] No space
   left on device`.
4. `df -h /var/log/heartbeat` → `100%` used, `0` available.

**Resolution:**

```
# find what's actually eating the space
ls -la /var/log/heartbeat/
# remove whatever it turns out to be (a hidden filler file in this case)
rm /var/log/heartbeat/.filler
systemctl restart heartbeat
```

**Why the health check didn't catch this — the actual lesson:** the
`/health` endpoint and the log-writing loop are two independent pieces of
the same process, running on separate threads. One dying doesn't crash the
other. A shallow health check that only proves "the process is alive and
the HTTP port answers" is not the same as proving "the service is doing its
actual job." This is a real, common gap in production monitoring —
liveness ≠ doing useful work.

**Verify:** run `./grade.sh` — it specifically checks the log is *still
advancing* a few seconds apart, not just that it exists.

</details>
