# Walkthrough — Heartbeat won't start after routine server maintenance

> ⚠️ **SPOILERS.** Work the incident from `ticket.md` first.

<details>
<summary>Hint 1 — Where to look first</summary>

Same first move as any "service down": ask systemd what state it's in and
why.

```
docker exec -it abhyas-legacy-vm bash
systemctl status heartbeat
```

</details>

<details>
<summary>Hint 2 — Narrowing it down</summary>

The status output will show the process exiting immediately — not a Python
traceback this time. Pull the journal:

```
journalctl -u heartbeat -n 20 --no-pager
```

There's a line starting with `python3:` (not `systemd:`) mentioning
"Permission denied" — that's the interpreter itself failing before your
code ever runs, which is a different layer of failure than the crash-loop
scenario's traceback.

</details>

<details>
<summary>Hint 3 — Root cause</summary>

`ExecStart` is `/usr/bin/python3 /opt/heartbeat/heartbeat.py` — python3 is
the thing actually being executed; the `.py` file is just an argument it
has to *read*. Check whether it still can:

```
ls -l /opt/heartbeat/heartbeat.py
```

Does the `heartbeat` user (the one the unit runs as) have read permission
on this file at all?

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl status heartbeat` → failed almost instantly, no app-level log.
2. `journalctl -u heartbeat -n 20 --no-pager` → a `python3:` line reads
   `can't open file '/opt/heartbeat/heartbeat.py': [Errno 13] Permission
   denied` — the interpreter itself can't read the file.
3. `ls -l /opt/heartbeat/heartbeat.py` → mode is `000` (`---------`), no
   permissions for anyone at all, including the `heartbeat` user that owns it.

**Resolution:**

```
chmod 755 /opt/heartbeat/heartbeat.py
systemctl restart heartbeat
systemctl status heartbeat
curl localhost:8080/health
```

**Why this is different from the crash-loop scenario:** there, Python
started running and then crashed partway through (an application-level
failure, with a traceback from *your* code). Here, python3 never even gets
to the first line — it fails trying to open the file at all. Whose name is
on the error line in the journal (`python3:` vs your own module/function
names in a traceback) is the fastest way to tell these two failure classes
apart.

**Verify:** run `./grade.sh`.

</details>
