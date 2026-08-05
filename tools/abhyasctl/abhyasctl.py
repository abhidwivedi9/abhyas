#!/usr/bin/env python3
"""abhyasctl — the Abhyas platform CLI.

Milestone 0 skeleton: command surface and scenario discovery only.
Cluster bring-up (`up`) lands in Milestone 3; the pager sim in Milestone 7.
Stdlib-only by design so it runs anywhere Python 3.10+ does.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

__version__ = "0.1.0"

REPO_ROOT = Path(__file__).resolve().parents[2]
SCENARIOS_DIR = REPO_ROOT / "scenarios"

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


def run_script(script: Path) -> int:
    return subprocess.call(["bash", str(script)])


# --- commands -----------------------------------------------------------------

def cmd_up(args: argparse.Namespace) -> int:
    print("abhyasctl up: not implemented yet — lands in Milestone 3 (Kubernetes core).")
    return 2


def cmd_down(args: argparse.Namespace) -> int:
    print("abhyasctl down: not implemented yet — lands in Milestone 3.")
    return 2


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
    return run_script(path / "inject.sh")


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


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="abhyasctl",
        description="Operate Abhyas, the SCG production simulator.",
    )
    parser.add_argument("--version", action="version", version=f"abhyasctl {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    p_up = sub.add_parser("up", help="bring up the full stack on kind (Milestone 3)")
    p_up.set_defaults(func=cmd_up)
    p_down = sub.add_parser("down", help="tear down the local stack (Milestone 3)")
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

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
