# Walkthrough — Daily report cron job has stopped producing output

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

```
docker exec -it abhyas-legacy-vm bash
ls -l /opt/heartbeat/daily_report.sh
```

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

Compare the permission bits against the crashloop and permission-denied
scenarios you've already solved. Does the `heartbeat` user (the one cron
runs this job as) have execute permission here?

Try running it exactly the way cron would, as a quick confirmation:

```
su -s /bin/bash heartbeat -c "env -i PATH=/usr/bin:/bin /opt/heartbeat/daily_report.sh"
```

</details>

<details>
<summary>Full investigation path</summary>

1. `ls -l /opt/heartbeat/daily_report.sh` -> mode is `644`, no execute bit.
2. Running it the way cron would fails immediately with "Permission
   denied" and exit code 126 (a different exit code than the "command not
   found" case from the PATH scenario — 126 specifically means "found the
   file, but couldn't execute it").

Resolution:

```
chmod +x /opt/heartbeat/daily_report.sh
```

Why exit code matters here: 126 vs 127 is a small but genuinely useful
distinction — 126 means the file exists but isn't executable (a
permissions problem), 127 means the shell couldn't find the command at all
(a PATH problem, like the previous cron scenario). Reading the exit code
alone can point you at the right category of fix before you even look
closely at the file.

Verify: run `./grade.sh` — it runs the job exactly the way cron does, the
same technique used in the PATH scenario.

</details>
