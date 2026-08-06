# Walkthrough — Daily report hasn't updated, but the script runs fine when I test it

> SPOILERS. Work the incident from `ticket.md` first.

<details>
<summary>Hint 1 - Where to look first</summary>

The ticket already tells you the trap: "it works when I run it by hand."
That phrase should immediately make you suspicious of environment
differences between how you're testing it and how cron actually runs it,
not the script's logic itself.

```
docker exec -it abhyas-legacy-vm bash
cat /opt/heartbeat/daily_report.sh
```

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

Notice the script calls a command by name only (not a full path). Where
does that command actually live?

```
which heartbeat-counter
echo $PATH
```

Now compare that against what cron itself actually gives a job to work
with, cron does NOT use your interactive shell's PATH. On Debian/Ubuntu,
cron's own default is much shorter (/usr/bin:/bin) unless a job's
crontab explicitly sets PATH=. Check:

```
crontab -l -u heartbeat
```

No PATH= line, so this job runs under cron's bare default, not yours.

</details>

<details>
<summary>Hint 3 - Root cause</summary>

Reproduce cron's actual environment directly, rather than guessing, this
is the real technique, not a workaround:

```
su -s /bin/bash heartbeat -c "env -i PATH=/usr/bin:/bin /opt/heartbeat/daily_report.sh"
```

</details>

<details>
<summary>Full investigation path</summary>

1. `cat /opt/heartbeat/daily_report.sh` -> calls `heartbeat-counter`
   unqualified (no full path).
2. `which heartbeat-counter` -> `/usr/local/bin/heartbeat-counter`.
   `/usr/local/bin` is on your interactive shell's PATH by default on
   Ubuntu, which is exactly why testing "by hand" works.
3. `crontab -l -u heartbeat` -> no PATH= override, so this job runs under
   cron's bare default (/usr/bin:/bin on Debian/Ubuntu), which does
   not include /usr/local/bin.
4. Reproducing that exact environment directly confirms it: running the
   script with an emulated cron PATH fails with "command not found",
   the real bug, caught without waiting for cron's actual 5-minute schedule.

Resolution (either works; the reference fix uses the first):

Option A: call the helper by its full path in the script:
```
sed -i 's|heartbeat-counter|/usr/local/bin/heartbeat-counter|' /opt/heartbeat/daily_report.sh
```

Option B: give the crontab entry an explicit PATH covering /usr/local/bin.

Why this matters beyond cron specifically: any process launched by
something other than an interactive login shell, cron, systemd, CI
runners, container entrypoints, typically gets a minimal, different PATH
than what you see day to day. "Works on my machine / works when I run it
manually" is often exactly this class of bug.

Verify: run `./grade.sh`, it deliberately runs the job the same way
cron would (a minimal emulated PATH), not via a normal shell, so it
can't be fooled the same way manual testing was.

</details>
