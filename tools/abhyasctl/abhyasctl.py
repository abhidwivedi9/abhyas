#!/usr/bin/env python3
"""abhyasctl — the Abhyas platform CLI.

Milestone 1: `up`/`down` drive the legacy-vm lab (platform/ansible/) — a
systemd-in-Docker box converged to its baseline by Ansible. Milestone 3
extends `up` to also bring up the kind cluster. Stdlib-only on the Python
side; docker/docker-compose are the only external dependencies, matching
the local-first principle (ADR-0003) — no Vagrant/VirtualBox required.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

__version__ = "0.1.0"

REPO_ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_DIR = REPO_ROOT / "scenarios"
ANSIBLE_DIR = REPO_ROOT / "platform" / "ansible"
COMPOSE_FILE = ANSIBLE_DIR / "docker-compose.yml"
LEGACY_VM_CONTAINER = "abhyas-legacy-vm"
STATE_FILE = REPO_ROOT / ".abhyas-state.json"

REQUIRED_SCENARIO_FILES = [
    "scenario.yaml",
    "ticket.md",
    "inject.sh",
    "walkthrough.md",
    "rca-reference.md",
    "interview.md",
    "grade.sh",
]


def discover_scenarios() -> list[Path]:
    """Return scenario directories (any dir under scenarios/ with a scenario.yaml),
    excluding the TEMPLATE."""
    if not SCENARIOS_DIR.is_dir():
        return []
    return sorted(
        p.parent
        for p in SCENARIOS_DIR.glob("*/*/scenario.yaml")
        if p.parent.name != "TEMPLATE"
    )


def find_scenario(scenario_id: str) -> Path:
    for path in discover_scenarios():
        if path.name == scenario_id:
            return path
    sys.exit(f"error: scenario '{scenario_id}' not found (try: abhyasctl scenario list)")


def find_bash() -> str:
    """On Windows, plain "bash" on PATH can resolve to the WSL launcher
    (C:\\Windows\\System32\\bash.exe), which expects /mnt/c/... paths, not
    C:/... ones — causing "No such file or directory" on a perfectly valid
    script. Prefer Git Bash explicitly when it's findable."""
    for candidate in (r"C:\Program Files\Git\bin\bash.exe", r"C:\Program Files\Git\usr\bin\bash.exe"):
        if Path(candidate).is_file():
            return candidate
    found = shutil.which("bash")
    return found or "bash"


def run_script(script: Path) -> int:
    # bash treats backslashes as escape characters, so a raw Windows path
    # (C:\Users\...) gets mangled into garbage — pass forward slashes instead.
    env = os.environ.copy()
    # Scenario scripts pass container-internal paths (e.g. /opt/heartbeat/...)
    # to `docker exec`. MSYS's bash auto-rewrites POSIX-looking args into
    # Windows paths before non-MSYS executables (like docker.exe) ever see
    # them — harmless on Linux/CI, but silently corrupts these paths on
    # Windows. Disabling it is a no-op everywhere except Git Bash on Windows.
    env["MSYS_NO_PATHCONV"] = "1"
    env["MSYS2_ARG_CONV_EXCL"] = "*"
    return subprocess.call([find_bash(), str(script).replace("\\", "/")], env=env)


# --- commands -----------------------------------------------------------------

def compose(*args: str) -> int:
    return subprocess.call(["docker", "compose", "-f", str(COMPOSE_FILE), *args])


def wait_for_systemd(container: str, timeout: int = 30) -> bool:
    """Poll until the container's systemd PID 1 answers, so Ansible isn't
    racing container startup."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = subprocess.run(
            ["docker", "exec", container, "systemctl", "is-system-running"],
            capture_output=True, text=True,
        )
        # "running" or "degraded" both mean systemd is up and answering;
        # only a hard failure to exec means it's not ready yet.
        if result.returncode in (0, 1):
            return True
        time.sleep(1)
    return False


def cmd_up(args: argparse.Namespace) -> int:
    print("[up] building legacy-vm and ansible-control images...")
    if compose("build", "legacy-vm", "ansible-control") != 0:
        return 1

    print("[up] starting legacy-vm (systemd-in-Docker, no VirtualBox/Vagrant needed)...")
    if compose("up", "-d", "legacy-vm") != 0:
        return 1

    print("[up] waiting for systemd inside legacy-vm to come up...")
    if not wait_for_systemd(LEGACY_VM_CONTAINER):
        print("error: legacy-vm's systemd never became ready", file=sys.stderr)
        return 1

    print("[up] converging legacy-vm to baseline with Ansible...")
    rc = compose(
        "run", "--rm", "ansible-control",
        "-i", "inventory/legacy-vm.yml", "playbooks/site.yml",
    )
    if rc != 0:
        return rc

    print("[up] done. legacy-vm is healthy and running the heartbeat service.")
    print(f"     shell in with:  docker exec -it {LEGACY_VM_CONTAINER} bash")
    print("     start a scenario with:  abhyasctl scenario start <id>")
    return 0


def cmd_down(args: argparse.Namespace) -> int:
    print("[down] stopping and removing the legacy-vm lab...")
    return compose("down", "-v")


def cmd_scenario_list(args: argparse.Namespace) -> int:
    scenarios = discover_scenarios()
    if not scenarios:
        print("No scenarios yet. First batch ships with Milestone 1.")
        return 0
    for path in scenarios:
        print(f"{path.name}  ({path.parent.name})")
    return 0


def cmd_scenario_start(args: argparse.Namespace) -> int:
    path = find_scenario(args.id)
    print(f"Starting scenario {args.id}...")
    print(f"Your ticket: {path / 'ticket.md'}")
    rc = run_script(path / "inject.sh")
    if rc == 0:
        # Records which scenario the dashboard should show as the active
        # incident. Local-only, gitignored — not shared state.
        STATE_FILE.write_text(json.dumps({
            "active_scenario": args.id,
            "started_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
        }))
    return rc


def cmd_scenario_grade(args: argparse.Namespace) -> int:
    path = find_scenario(args.id)
    return run_script(path / "grade.sh")


def cmd_scenario_verify(args: argparse.Namespace) -> int:
    """Structural lint: every scenario has all required files; scripts are executable stubs."""
    scenarios = discover_scenarios()
    template = SCENARIOS_DIR / "TEMPLATE"
    targets = ([template] if template.is_dir() else []) + scenarios
    failures = 0
    for path in targets:
        missing = [f for f in REQUIRED_SCENARIO_FILES if not (path / f).is_file()]
        if missing:
            print(f"FAIL {path.relative_to(REPO_ROOT)}: missing {', '.join(missing)}")
            failures += 1
        else:
            print(f"ok   {path.relative_to(REPO_ROOT)}")
    if failures:
        sys.exit(f"{failures} scenario(s) failed structural verification")
    print(f"{len(targets)} scenario dir(s) verified")
    return 0


def cmd_pager(args: argparse.Namespace) -> int:
    print("abhyasctl pager: not implemented yet — lands in Milestone 7 (Observability).")
    return 2


def cmd_dashboard(args: argparse.Namespace) -> int:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import dashboard  # noqa: E402 (local import; see sys.path insert above)
    dashboard.run_dashboard(port=args.port, open_browser=not args.no_browser)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="abhyasctl",
        description="Operate Abhyas, the SCG production simulator.",
    )
    parser.add_argument("--version", action="version", version=f"abhyasctl {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    p_up = sub.add_parser("up", help="bring up the legacy-vm lab (Milestone 1); extends to kind in Milestone 3")
    p_up.set_defaults(func=cmd_up)
    p_down = sub.add_parser("down", help="tear down the local lab")
    p_down.set_defaults(func=cmd_down)

    p_scenario = sub.add_parser("scenario", help="run and grade scenarios")
    scen_sub = p_scenario.add_subparsers(dest="scenario_command", required=True)
    scen_sub.add_parser("list", help="list available scenarios").set_defaults(func=cmd_scenario_list)
    p_start = scen_sub.add_parser("start", help="inject a scenario's fault and open its ticket")
    p_start.add_argument("id")
    p_start.set_defaults(func=cmd_scenario_start)
    p_grade = scen_sub.add_parser("grade", help="verify your fix is real")
    p_grade.add_argument("id")
    p_grade.set_defaults(func=cmd_scenario_grade)
    scen_sub.add_parser("verify", help="structural lint of all scenario dirs (CI)").set_defaults(
        func=cmd_scenario_verify
    )

    p_pager = sub.add_parser("pager", help="the PagerDuty simulator (Milestone 7)")
    p_pager.set_defaults(func=cmd_pager)

    p_dash = sub.add_parser("dashboard", help="local status page: milestone progress + live scenario state")
    p_dash.add_argument("--port", type=int, default=4000)
    p_dash.add_argument("--no-browser", action="store_true", help="don't auto-open a browser tab")
    p_dash.set_defaults(func=cmd_dashboard)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
