# Walkthrough — Heartbeat failing to start after a config change

> ⚠️ **SPOILERS.** Work the incident from `ticket.md` first.

<details>
<summary>Hint 1 — Where to look first</summary>

```
docker exec -it abhyas-legacy-vm bash
systemctl status heartbeat
```

Look closely at the exit status code shown, not just "failed."

</details>

<details>
<summary>Hint 2 — Narrowing it down</summary>

The status line shows something like `status=217/USER` — that specific
step name (`USER`) tells you systemd failed while resolving *who* to run
the process as, before it ever got to actually launching python3. Confirm
with the journal:

```
journalctl -u heartbeat -n 10 --no-pager
```

</details>

<details>
<summary>Hint 3 — Root cause</summary>

```
systemctl cat heartbeat
```

Check the `User=` line in `[Service]` against the actual users that exist
on the box (`getent passwd heartbeat`, `id heartbeat`).

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl status heartbeat` → `status=217/USER` — a specific systemd
   exec-step failure code meaning "couldn't resolve the configured user."
2. `journalctl -u heartbeat -n 10 --no-pager` → "Failed to determine user
   credentials: No such process" / "Failed at step USER."
3. `systemctl cat heartbeat` → `User=ghostuser`.
4. `id ghostuser` → no such user on this box. The real `heartbeat` service
   account exists (`id heartbeat` succeeds) — the unit is just pointing at
   the wrong name.

**Resolution:**

```
sed -i 's/User=ghostuser/User=heartbeat/' /etc/systemd/system/heartbeat.service
systemctl daemon-reload
systemctl restart heartbeat
systemctl status heartbeat
curl localhost:8080/health
```

**Why `daemon-reload` matters here specifically:** you edited a unit file
directly on disk — systemd caches parsed unit files in memory and won't
notice the edit until told to re-read it. Skipping this step is a common
trap: `systemctl restart` will appear to run but use the *old* (broken)
in-memory definition.

**Verify:** run `./grade.sh`.

</details>
