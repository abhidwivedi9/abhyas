# Walkthrough — Heartbeat down, restart attempts having no effect

> ⚠️ **SPOILERS.** Work the incident from `ticket.md` first.

<details>
<summary>Hint 1 — Where to look first</summary>

```
docker exec -it abhyas-legacy-vm bash
systemctl status heartbeat
systemctl start heartbeat
```

Read the exact wording of any error from the `start` attempt — don't just
retry it.

</details>

<details>
<summary>Hint 2 — Narrowing it down</summary>

`systemctl status` shows something different from every other scenario so
far: `Loaded: masked`. That's not "failed" and it's not "crash-looping" — it
means systemd has been explicitly told never to start this unit, full stop.
`systemctl start` will refuse outright rather than attempt anything.

</details>

<details>
<summary>Hint 3 — Root cause</summary>

```
ls -la /etc/systemd/system/heartbeat.service
```

What kind of filesystem object is this now? Compare it to what a normal
unit file looks like.

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl status heartbeat` → `Loaded: masked (Reason: Unit
   heartbeat.service is masked.)`.
2. `systemctl start heartbeat` → refuses immediately: "Unit heartbeat.service
   is masked."
3. `ls -la /etc/systemd/system/heartbeat.service` → it's a symlink to
   `/dev/null`, not a real unit file. This is literally what "masked" means
   at the filesystem level — someone (or some script) ran the equivalent of
   `systemctl mask heartbeat` here, almost certainly by mistake while
   working on a different service.

**Resolution:**

```
systemctl unmask heartbeat
systemctl status heartbeat
```

You'll find the unit still won't start — `unmask` only removes the
`/dev/null` symlink. If the *original* unit file was deleted before the
mask was applied (as it was here), there's nothing left to load. Restart
attempts fail differently now ("Unit heartbeat.service not found") rather
than "masked" — a subtly different error worth noticing.

The actual fix is to restore the real unit definition from source of
truth, not hand-write one from memory:

```
# from your HOST machine, not inside the container
abhyasctl up
```

This re-runs the Ansible convergence, which recreates the unit file exactly
as configuration management defines it, re-enables it, and starts it.

**Why this matters:** if you'd hand-written a replacement unit file
in-container instead, it would drift from what's in git the moment anyone
re-converges the box — this is exactly the kind of drift Milestone 6
(GitOps) exists to prevent at the application-deployment layer, and the
same discipline applies to system configuration.

**Verify:** run `./grade.sh`.

</details>
