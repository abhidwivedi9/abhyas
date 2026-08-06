# Interview Mapping — Heartbeat crash-looping right after another team's deploy on the same host

## Troubleshooting questions

Q: "A service fails to start with 'address already in use.' Walk me
through resolving it safely."

Strong answer sketch: First identify exactly what's holding the port
(`ss -ltnp` or equivalent) and what that process actually is — don't
assume, confirm. Only after positively identifying it as safe to remove
(unrelated, not something else depending on it) should you free the port,
then restart the affected service. The "safely" in the question is doing
real work: blindly killing whatever holds a contested port on a shared
host risks turning one incident into two.

## System design angle

Q: "What's the underlying architectural reason multiple services on one
host can collide like this, and how do modern platforms avoid it?"

Strong answer sketch: On a traditional shared host, every process
competes for the same flat port namespace — there's no isolation between
"my service's port 8080" and "someone else's port 8080." Containers (and
Kubernetes Pods specifically) give each workload its own network
namespace, so port 8080 inside one container has nothing to do with port
8080 inside another — collisions like this one become structurally
impossible rather than something you have to police via a registry and
convention. This scenario's fix is operational (find and remove the
conflict); the deeper fix is architectural (isolate the network
namespace), which is exactly what Milestone 2-3 introduce.

## Behavioral / STAR

Q: "Tell me about an incident caused by someone else's unrelated change
on shared infrastructure."

- S: A completely unrelated team's ad-hoc process on a shared host
  happened to bind the same port a production service needed on its next
  restart.
- T: Restore service without assuming blame or breaking anything else on
  the shared host.
- A: Used the specific OS-level error to immediately rule out an
  application bug, identified exactly what held the port before touching
  anything, confirmed it was safe to remove, and only then freed the port.
- R: Fast, safe recovery; RCA identified the deeper architectural gap
  (no port isolation on shared hosts) rather than treating it as an
  isolated one-off mistake.
