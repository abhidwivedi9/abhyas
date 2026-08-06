# The "legacy VM" target: a real systemd-driven Linux box, packaged as a
# container so no hypervisor (VirtualBox/Vagrant) is required. Milestone 1
# scenarios (broken services, disk pressure, cron, permissions) run against
# this image. Ansible in ../control/ converges it to the healthy baseline.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# systemd itself + the toolset a real on-call engineer would use to triage:
# cron, ssh (for realism/inventory), rsyslog (real logs, not just stdout),
# and Python (required for Ansible to manage the box at all).
RUN apt-get update && apt-get install -y --no-install-recommends \
        systemd systemd-sysv \
        cron rsyslog openssh-server logrotate \
        python3 sudo iproute2 procps \
        vim less curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    # Strip units systemd would otherwise fail to start in a container
    # (no real hardware, no real network device management needed here).
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl*

RUN mkdir -p /var/run/sshd && ssh-keygen -A

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
