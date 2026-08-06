# The Ansible control node. Runs the playbooks against the legacy-vm
# container using Ansible's docker connection plugin (docker exec under the
# hood) — no SSH keys, no host-installed Ansible, works identically on
# Windows/macOS/Linux wherever Docker runs. Local-first per ADR-0003.
FROM python:3.12-slim

# community.docker's docker connection plugin shells out to the `docker`
# CLI (not just the Python SDK) to exec into the target container.
# docker-cli ships /usr/bin/docker; docker.io/dockerd is not needed here —
# this container only ever talks to the *host's* daemon via the mounted
# socket, it never runs its own.
RUN apt-get update && apt-get install -y --no-install-recommends docker-cli \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir ansible-core==2.17.* docker \
    && ansible-galaxy collection install community.docker

WORKDIR /workspace
ENTRYPOINT ["ansible-playbook"]
