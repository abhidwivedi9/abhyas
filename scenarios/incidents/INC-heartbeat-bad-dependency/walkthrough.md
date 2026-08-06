# Walkthrough — Heartbeat won't come back up after a maintenance window

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

```
docker exec -it abhyas-legacy-vm bash
systemctl start heartbeat
```

Read the exact error message the command itself gives you — don't just
check `systemctl status` this time, the command's own output is the
fastest signal.

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

The error names a specific unit. Does that unit actually exist on this
box?

```
systemctl status ghost-dependency.service
```

</details>

<details>
<summary>Full investigation path</summary>

1. `systemctl start heartbeat` -> fails immediately: "Unit
   ghost-dependency.service not found." This is systemd refusing to even
   queue the start job, because it can't resolve a hard dependency.
2. `systemctl cat heartbeat` -> shows `Requires=ghost-dependency.service`
   and `After=ghost-dependency.service` in `[Unit]`.
3. `systemctl status ghost-dependency.service` -> confirms it genuinely
   doesn't exist — matches the ticket's mention of a decommissioned
   internal dependency.

Resolution:

```
sed -i '/^Requires=ghost-dependency.service$/d;/^After=ghost-dependency.service$/d' \
  /etc/systemd/system/heartbeat.service
systemctl daemon-reload
systemctl start heartbeat
systemctl status heartbeat
curl localhost:8080/health
```

Why `Requires=` is stricter than you might expect: unlike `Wants=` (a
soft dependency — the depended-on unit is started if possible, but its
absence or failure doesn't block the dependent unit), `Requires=` is
hard — if the required unit can't even be found, systemd refuses to start
this unit at all. Decommissioning something still `Requires=`'d by
another unit is a direct, immediate outage for the dependent unit, not a
gradual degradation.

Verify: run `./grade.sh` — it restarts the unit from a fully stopped
state and confirms systemd itself is satisfied with the dependency graph,
not just that the process happens to be running.

</details>
