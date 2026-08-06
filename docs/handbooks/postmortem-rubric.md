# Postmortem Rubric

Used to self-grade your RCA against a scenario's `rca-reference.md`. Blameless
throughout: score the *artifact*, never the person who wrote it or caused
the incident.

## Scoring (4 points each, 20 total)

| Criterion | 0 | 2 | 4 |
|---|---|---|---|
| **Timeline** | Missing or vague | Key events present, timing approximate | Precise, covers injection → detection → resolution |
| **Root cause vs. trigger** | Names the trigger only (e.g. "the deploy") | Root cause named but shallow | Root cause is the actual mechanism — explains *why* the trigger caused *this* failure |
| **Contributing factors** | None identified | One identified | Process/tooling gaps identified, not just the immediate bug |
| **Blamelessness** | Blames a person or team | Neutral but generic | Focused entirely on systems/process; a person reading it wouldn't feel targeted |
| **Action items** | Missing or vague ("be more careful") | Present but not owned/typed | Specific, typed (prevent/detect/mitigate), owned by a role, prioritized |

**16-20:** strong, ship it. **10-15:** solid but revise weak criteria before
moving on. **Below 10:** rewrite — compare line-by-line against the
scenario's `rca-reference.md` and see what's missing.

## The one habit that separates strong RCAs from weak ones

Ask "why" one more time than feels necessary. "The service crashed" →
why? "A bad import" → why did that reach production? "No pre-deploy check" →
*that's* usually where the real action item lives, not at the first answer.
