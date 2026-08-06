# Walkthrough — Heartbeat service down, health checks failing

> ⚠️ **SPOILERS.** Work the incident from `ticket.md` first. Open one section
> at a time, only when stuck for 20+ minutes.

<details>
<summary>Hint 1 — Where to look first</summary>

Shell into the box and ask systemd directly what state the service is in —
don't guess, don't restart it blind. A real on-call engineer's first move on
any "service down" page is always the same question: *what does systemd
itself say happened?*

```
docker exec -it abhyas-legacy-vm bash
systemctl status heartbeat
```

</details>

<details>
<summary>Hint 2 — Narrowing it down</summary>

`systemctl status` will show the service bouncing between `activating
(auto-restart)` and a failed exit — and if you watch it for a few seconds,
the restart counter keeps climbing. That tells you *something crashes
immediately on every single start*, not that it crashed once under load.

The next question: crashes with what error? `systemctl status` only shows
the last couple of log lines — pull the full journal for the service:

```
journalctl -u heartbeat -n 50 --no-pager
```

Read the actual Python traceback. It'll point at one specific line.

</details>

<details>
<summary>Hint 3 — Root cause</summary>

The traceback is a `ModuleNotFoundError` on the very first line of
`/opt/heartbeat/heartbeat.py` — an import statement is referencing a module
that doesn't exist. Compare it against what a working Python standard-library
import should look like:

```
cat /opt/heartbeat/heartbeat.py | head -5
```

Somebody's "deploy" introduced a typo in the import. This is why the ticket
mentioned a recent deploy — that's your actual lead, not a red herring.

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl status heartbeat` → cycling through `activating (auto-restart)`
   and failed exits; watch it twice a second apart and the restart counter
   is climbing.
2. `journalctl -u heartbeat -n 50 --no-pager` → traceback shows
   `ModuleNotFoundError: No module named 'http.serverx'` on the import line,
   repeated on every single attempt.
3. `sed -n '1,10p' /opt/heartbeat/heartbeat.py` → confirms the import reads
   `import http.serverx` instead of `import http.server`.

**Resolution:**

```
# fix the actual bug — restore the correct import
sed -i 's/import http\.serverx/import http.server/' /opt/heartbeat/heartbeat.py
systemctl restart heartbeat

# confirm
systemctl status heartbeat
curl localhost:8080/health
```

**Why "just restart it" alone never works here:** the running process is
already crash-looping *because of* the broken file on disk — restarting
without editing `heartbeat.py` first just restarts it into the same crash.
The fix has to touch the actual file.

**Verify:** exit the container and run `./grade.sh` — it must pass. Grading
checks that the restart counter has genuinely stopped climbing (not just
that the service happens to be up in this exact instant), so a cosmetic fix
that doesn't touch the real file will not pass.

</details>
