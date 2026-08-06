# INC-daily-report-cron-path: Daily report hasn't updated, but the script runs fine when I test it

> **Severity:** Sev-3 · **Tier:** L1 · **Role:** SRE on-call · **Time-box:** 25 min

## What the pager says

```
[FIRING] DailyReportStale — report.log on legacy-vm has not been updated
by its scheduled job in over 15 minutes.
```

## What the customer / stakeholder says

> "The daily facility summary job seems to have stopped — that's the one
> that rolls up life-support telemetry counts for the ops team. Weird
> thing is, when I SSH in and just run the script by hand, it works
> completely fine. I don't get it."

## What you know

- Environment: legacy-vm (local lab)
- Job: `daily_report.sh`, scheduled every 5 minutes via cron, runs as the
  `heartbeat` user
- Recent changes: the team added a small helper tool to make the report
  script simpler, installed under `/usr/local/bin` earlier today

## Acceptance criteria

- [ ] The scheduled job succeeds and `report.log` is updating again
- [ ] `grade.sh` passes
- [ ] RCA drafted

## Getting started

```
abhyasctl scenario start INC-daily-report-cron-path
```

```
docker exec -it abhyas-legacy-vm bash
```

Stuck for 20+ minutes? `walkthrough.md` is spoiler-gated.
