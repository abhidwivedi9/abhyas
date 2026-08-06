# Walkthrough — Cart service process count climbing steadily, no obvious cause

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

The app itself is responding fine, so this isn't an application crash.
Look at the container's process table directly:

```
docker exec -it abhyas-cart-service ps -o pid,ppid,stat,comm
```

Run it, wait a few seconds, run it again. What's changing?

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

Look closely at the `STAT` column. `Z` means zombie — a process that has
already exited but hasn't been reaped by its parent. Check the `PPID`
column for those entries — who's supposed to be cleaning them up?

</details>

<details>
<summary>Hint 3 - Root cause</summary>

Zombies owned by PID 1 specifically are a known container pattern: PID 1
inside a container has to take on init's reaping responsibility, and most
application processes (uvicorn here) were never written to do that for
processes they didn't create.

</details>

<details>
<summary>Full investigation path</summary>

1. `ps -o pid,ppid,stat,comm` sampled twice → a growing list of entries
   with `STAT Z`, all owned by `PPID 1`.
2. `PID 1` here is `uvicorn` — it's the container's init by default (no
   `tini`/`--init` in this image), and it never explicitly reaps
   processes it didn't fork itself. Once a zombie's original parent is
   gone, it's reparented to PID 1 and stays a zombie forever unless PID 1
   calls `wait()` on it — which a plain application process doesn't do.
3. Confirms the ticket's lead: "someone ran a one-off maintenance/debug
   script" — something was forking children and exiting without
   reaping them, and once that something is also gone, its orphaned
   children permanently belong to PID 1.

**Resolution:**

```
docker restart abhyas-cart-service
```

**Why a restart is the correct fix here, not a shortcut:** you cannot
safely `wait()` on zombies you didn't fork from outside the process that
owns them — there's no clean way to reap someone else's children without
modifying the running application's code. A container restart clears the
entire process namespace and starts clean, which is the practical,
correct remedy in this exact situation. (For production hardening, the
durable version of this fix is adding a proper init — `tini` or
`--init` — to the container so *future* leaks like this get reaped
automatically instead of accumulating.)

**Why the app stayed responsive the whole time:** zombie processes
consume almost no resources (just a process-table slot) — they don't
compete for CPU or meaningfully for memory. The real risk isn't
performance degradation, it's process-table/PID exhaustion if left
unchecked for long enough, which is why this is worth fixing even though
nothing looked broken from the outside.

**Verify:** run `./grade.sh` — it checks the zombie count twice, several
seconds apart, so a lucky snapshot between generator ticks won't pass.

</details>
