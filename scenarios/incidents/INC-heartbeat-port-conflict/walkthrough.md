# Walkthrough — Heartbeat crash-looping right after another team's deploy on the same host

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

```
docker exec -it abhyas-legacy-vm bash
systemctl status heartbeat
journalctl -u heartbeat -n 15 --no-pager
```

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

The journal shows a Python traceback again, but read closely — is this
your application's own logic failing, or is it failing before it even
gets to running your code, at the network layer? The specific OSError
message tells you exactly what kind of conflict this is.

</details>

<details>
<summary>Hint 3 - Root cause</summary>

Once you know it's a port conflict, the real question is: who else is
using it?

```
ss -ltnp | grep 8080
```

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl status heartbeat` / `journalctl -u heartbeat -n 15` -> a
   traceback ending in `OSError: [Errno 98] Address already in use` at
   the `socket.bind()` call. This is failing before your code's own
   logic runs at all — it's a network-layer conflict, not an application bug.
2. `ss -ltnp | grep 8080` -> shows a process already listening on :8080,
   with its PID.
3. Check what that process actually is (`ps -p <PID> -f`) — matches the
   "ad-hoc diagnostic tool" the ticket mentioned another team started.

Resolution:

```
# find the PID actually holding the port
ss -ltnp | grep 8080

# confirm what it is before killing it — don't blindly kill unknown PIDs
ps -p <PID> -f

# once confirmed it's the unrelated process, not something you need:
kill <PID>

systemctl restart heartbeat
systemctl status heartbeat
curl localhost:8080/health
```

Why "confirm before you kill" matters: on a real shared host, blindly
killing whatever holds a contested port is how you turn one incident into
two. Identify it first.

Verify: run `./grade.sh` — it specifically checks that the PID bound to
:8080 matches heartbeat's own process ID, not just that "some python3
process" is listening (both the rogue process and heartbeat itself are
named `python3`, so a name-only check could pass falsely).

</details>
