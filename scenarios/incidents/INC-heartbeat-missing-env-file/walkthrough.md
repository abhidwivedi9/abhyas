# Walkthrough — Heartbeat completely refuses to start after a partial config rollout

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

```
docker exec -it abhyas-legacy-vm bash
systemctl status heartbeat
```

Compare this failure's shape against the crash-loop scenario you solved
earlier — is there an application-level Python traceback here at all?

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

If there's no Python traceback anywhere, the process never even started —
systemd itself is refusing the job before your code runs. Check the full
journal and the unit definition itself:

```
journalctl -u heartbeat -n 15 --no-pager
systemctl cat heartbeat
```

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl status heartbeat` -> fails with `Result: resources`, no
   application-level log line anywhere.
2. `journalctl -u heartbeat -n 15 --no-pager` -> `Failed to load
   environment files: No such file or directory`.
3. `systemctl cat heartbeat` -> shows an `EnvironmentFile=` line pointing
   at `/etc/heartbeat/heartbeat.env`.
4. `ls /etc/heartbeat/heartbeat.env` -> doesn't exist. This directive was
   part of a config rollout that never finished — the unit file references
   a file that was supposed to ship alongside it but didn't.

Resolution (either is valid; pick based on what the rollout was actually
meant to do):

```
# Option A: the rollout is abandoned/rolled back — remove the reference
sed -i '/^EnvironmentFile=/d' /etc/systemd/system/heartbeat.service
systemctl daemon-reload
systemctl reset-failed heartbeat
systemctl restart heartbeat

# Option B: the rollout should have shipped this file — create it
mkdir -p /etc/heartbeat
touch /etc/heartbeat/heartbeat.env
systemctl reset-failed heartbeat
systemctl restart heartbeat
```

Why this failure mode is worth recognizing on sight: unlike the
crash-loop scenario (where Python starts and then dies), here systemd
refuses to even attempt starting the process — `EnvironmentFile=` without
a leading `-` is treated as mandatory, and a missing mandatory file is a
hard stop. The complete absence of any application-level log line is
itself the clue that this is a unit-definition problem, not application code.

Verify: run `./grade.sh` — it accepts either valid fix (remove the
reference or supply the file), it only checks the actual outcome.

</details>
