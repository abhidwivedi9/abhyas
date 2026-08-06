# Walkthrough — Cart service repeatedly restarting, customers losing cart contents

> SPOILERS. Work the incident from ticket.md first.

<details>
<summary>Hint 1 - Where to look first</summary>

```
docker ps --filter name=abhyas-cart-service
docker inspect abhyas-cart-service --format "RestartCount={{.RestartCount}}"
```

Run the second command twice, a few seconds apart. Is the count climbing?

</details>

<details>
<summary>Hint 2 - Narrowing it down</summary>

A climbing restart count with no code deploy in the ticket points at the
container's own resource envelope, not application logic. Check whether
the container has been killed by the kernel, not just stopped:

```
docker inspect abhyas-cart-service --format "OOMKilled={{.State.OOMKilled}}"
```

</details>

<details>
<summary>Hint 3 - Root cause</summary>

```
docker inspect abhyas-cart-service --format "{{.HostConfig.Memory}}"
docker stats --no-stream abhyas-cart-service
```

Compare the configured limit against what the process actually needs just
to start up.

</details>

<details>
<summary>Full investigation path</summary>

1. `docker inspect ... RestartCount` sampled twice -> climbing every few
   seconds. This is a live, ongoing crash loop, not a historical event.
2. `docker inspect ... OOMKilled` -> `true`. The kernel is killing this
   container's process, not the application exiting on its own.
3. `docker inspect ... HostConfig.Memory` -> 20971520 bytes (20MB). Compare
   against `docker stats` on a healthy sibling container, or just recall
   that a Python/uvicorn process needs roughly 40-50MB at idle -- 20MB
   isn't enough to even finish starting up, so every restart attempt
   fails identically and immediately, forever.

Resolution:

```
docker update --memory 128m --memory-swap 128m abhyas-cart-service
docker restart abhyas-cart-service
```

For a durable fix (not just a live patch that a future redeploy would
undo), the real fix also updates apps/docker-compose.yml's mem_limit for
cart-service so the correct value is what gets deployed next time, not
just what's running right now.

Why this matters beyond this one incident: a resource limit set below
what a process needs to even start produces a signature that's easy to
misdiagnose as "the app is broken" when it's actually "the app was never
given enough room to run." This exact pattern -- CrashLoopBackOff caused
by an undersized memory request/limit -- is one of the most common real
Kubernetes incidents, and Milestone 3 revisits it in that context.

Verify: run `./grade.sh` -- it checks stability over a real time window,
not a single lucky snapshot, so a restart that happens to catch a brief
"running" moment won't fool it.

</details>
