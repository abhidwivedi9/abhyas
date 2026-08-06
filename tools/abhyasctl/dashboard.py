#!/usr/bin/env python3
"""abhyasctl dashboard — a tiny local status page.

Stdlib-only, same promise as abhyasctl itself: no pip installs, no cloud
account, no signup, $0 cost, runs entirely on your machine. This is NOT the
real observability stack (Prometheus/Grafana land in Milestone 7) — it's an
honest, live view of milestone progress and scenario state in the meantime.
Every status shown is a real check against the running legacy-vm container,
not simulated data.
"""
from __future__ import annotations

import http.server
import json
import re
import socketserver
import webbrowser
from pathlib import Path

import abhyasctl

REPO_ROOT = abhyasctl.REPO_ROOT
PROGRESS_FILE = REPO_ROOT / "docs" / "progress.json"
STATE_FILE = REPO_ROOT / ".abhyas-state.json"

STATUS_LABEL = {
    "done": ("✅", "done"),
    "in_progress": ("🔨", "in progress"),
    "pending": ("⏳", "pending"),
}

# One-line "what this trains" per scenario, matching the full Q&A in each
# scenario's interview.md and compiled in docs/handbooks/interview-handbook.md.
# Keep this in sync when a new scenario's interview.md is added.
INTERVIEW_TOPICS = {
    "INC-heartbeat-crashloop": "Reading a traceback in journalctl; restart-loop signatures",
    "INC-heartbeat-permission-denied": "OS-level vs. application-level failure",
    "INC-heartbeat-masked": "systemd mask vs. disable; config as source of truth",
    "INC-heartbeat-wrong-user": "Reading systemd exit-status codes (217/USER)",
    "INC-heartbeat-disk-full": "Health checks that lie: liveness vs. actually working",
    "INC-heartbeat-log-permission-denied": "Recurring incidents & prioritizing prevention",
    "INC-daily-report-cron-path": "Scheduler environment vs. interactive shell PATH",
    "INC-daily-report-not-executable": "Exit code 126 vs. 127",
    "INC-logrotate-misconfigured": "Silent misconfiguration; verifying vs. inspecting",
    "INC-heartbeat-port-conflict": "Shared-host resource contention; confirm before you kill",
    "INC-heartbeat-missing-env-file": "Partial/non-atomic rollouts",
    "INC-heartbeat-bad-dependency": "systemd Requires= vs Wants=; dependency audits",
}


def read_state() -> dict:
    if STATE_FILE.is_file():
        try:
            return json.loads(STATE_FILE.read_text())
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def scenario_meta(scenario_dir: Path) -> dict:
    """Pull title/tier out of scenario.yaml without a YAML dependency —
    the format is deliberately flat (see docs/scenario-authoring.md), so a
    couple of targeted regexes are enough; this is not a general parser."""
    text = (scenario_dir / "scenario.yaml").read_text()
    title = re.search(r'^title:\s*"(.*)"', text, re.MULTILINE)
    tier = re.search(r"^tier:\s*(\S+)", text, re.MULTILINE)
    category = re.search(r"^category:\s*(\S+)", text, re.MULTILINE)
    return {
        "title": title.group(1) if title else scenario_dir.name,
        "tier": tier.group(1) if tier else "?",
        "category": category.group(1) if category else "?",
    }


def check_live_status(scenario_id: str) -> str:
    """Real check: actually runs grade.sh against the live container.
    Returns 'firing', 'resolved', or 'unknown' (container/scenario unreachable)."""
    path = None
    for p in abhyasctl.discover_scenarios():
        if p.name == scenario_id:
            path = p
            break
    if path is None:
        return "unknown"
    rc = abhyasctl.run_script(path / "grade.sh")
    return "resolved" if rc == 0 else "firing"


def build_html() -> str:
    milestones = []
    if PROGRESS_FILE.is_file():
        milestones = json.loads(PROGRESS_FILE.read_text()).get("milestones", [])

    scenarios = [(p, scenario_meta(p)) for p in abhyasctl.discover_scenarios()]
    state = read_state()
    active_id = state.get("active_scenario")
    active_status = check_live_status(active_id) if active_id else None

    # --- Firing alerts panel ---------------------------------------------
    if active_status == "firing":
        meta = next((m for p, m in scenarios if p.name == active_id), {})
        alerts_html = f"""
        <div class="alert firing">
          <span class="dot"></span>
          <div>
            <strong>[FIRING] {active_id}</strong> — {meta.get('title', '')}<br>
            <span class="muted">Run <code>abhyasctl scenario grade {active_id}</code> after you fix it, or just refresh this page.</span>
          </div>
        </div>"""
    elif active_status == "resolved":
        meta = next((m for p, m in scenarios if p.name == active_id), {})
        alerts_html = f"""
        <div class="alert resolved">
          <span class="dot"></span>
          <div><strong>[RESOLVED] {active_id}</strong> — {meta.get('title', '')} is healthy again.</div>
        </div>"""
    else:
        alerts_html = '<div class="alert none">No active incident. Run <code>abhyasctl scenario start &lt;id&gt;</code> to begin one.</div>'

    # --- Milestone progress table -----------------------------------------
    ms_rows = ""
    for m in milestones:
        icon, label = STATUS_LABEL.get(m["status"], ("?", m["status"]))
        extra = ""
        if "scenarios_total" in m:
            extra = f" — {m.get('scenarios_done', 0)}/{m['scenarios_total']} scenarios"
        ms_rows += f"""
        <tr class="{m['status']}">
          <td>{m['id']}</td>
          <td>{m['name']}</td>
          <td>{icon} {label}{extra}</td>
        </tr>"""

    # --- Scenario catalog table ---------------------------------------------
    sc_rows = ""
    for path, meta in scenarios:
        if path.name == active_id:
            badge = {"firing": '<span class="badge firing">🔴 FIRING</span>',
                      "resolved": '<span class="badge resolved">🟢 RESOLVED</span>'}.get(active_status, "")
        else:
            badge = '<span class="badge idle">⚪ available</span>'
        sc_rows += f"""
        <tr>
          <td><code>{path.name}</code></td>
          <td>{meta['title']}</td>
          <td>{meta['tier']}</td>
          <td>{meta['category']}</td>
          <td>{badge}</td>
        </tr>"""

    # --- Interview / RCA Q&A prep table -------------------------------------
    qa_rows = ""
    for path, meta in scenarios:
        topic = INTERVIEW_TOPICS.get(path.name, "see interview.md")
        qa_rows += f"""
        <tr>
          <td><code>{path.name}</code></td>
          <td>{topic}</td>
          <td><code>scenarios/incidents/{path.name}/interview.md</code></td>
        </tr>"""

    return f"""<!doctype html>
<html><head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="15">
<title>Abhyas — Status Dashboard</title>
<style>
  body {{ font-family: -apple-system, Segoe UI, sans-serif; background: #0d1117; color: #e6edf3; margin: 0; padding: 2rem; }}
  h1 {{ margin-bottom: 0.2rem; }}
  .sub {{ color: #8b949e; margin-bottom: 2rem; }}
  h2 {{ border-bottom: 1px solid #30363d; padding-bottom: 0.4rem; margin-top: 2.5rem; }}
  table {{ width: 100%; border-collapse: collapse; margin-top: 1rem; }}
  td, th {{ text-align: left; padding: 0.5rem 0.7rem; border-bottom: 1px solid #21262d; }}
  tr.done td:last-child {{ color: #3fb950; }}
  tr.in_progress td:last-child {{ color: #d29922; }}
  tr.pending td:last-child {{ color: #6e7681; }}
  code {{ background: #161b22; padding: 0.1rem 0.4rem; border-radius: 4px; }}
  .alert {{ display: flex; align-items: center; gap: 0.8rem; padding: 1rem 1.2rem; border-radius: 8px; margin-top: 1rem; }}
  .alert.firing {{ background: #3b1a1a; border: 1px solid #f85149; }}
  .alert.resolved {{ background: #142a1c; border: 1px solid #3fb950; }}
  .alert.none {{ background: #161b22; border: 1px solid #30363d; color: #8b949e; }}
  .dot {{ width: 12px; height: 12px; border-radius: 50%; flex-shrink: 0; }}
  .alert.firing .dot {{ background: #f85149; box-shadow: 0 0 8px #f85149; }}
  .alert.resolved .dot {{ background: #3fb950; }}
  .muted {{ color: #8b949e; font-size: 0.85em; }}
  .badge {{ padding: 0.2rem 0.6rem; border-radius: 12px; font-size: 0.85em; }}
  .badge.firing {{ background: #3b1a1a; color: #f85149; }}
  .badge.resolved {{ background: #142a1c; color: #3fb950; }}
  .badge.idle {{ background: #161b22; color: #8b949e; }}
  footer {{ margin-top: 3rem; color: #6e7681; font-size: 0.85em; }}
</style>
</head><body>
  <h1>Abhyas — Status Dashboard</h1>
  <div class="sub">Sachid Aquatics · legacy-vm lab · refreshes every 15s · $0 cost, runs entirely local</div>

  <h2>🚨 Active Incident</h2>
  {alerts_html}

  <h2>Milestone Progress</h2>
  <table>
    <tr><th>#</th><th>Milestone</th><th>Status</th></tr>
    {ms_rows}
  </table>

  <h2>Scenario Catalog</h2>
  <table>
    <tr><th>ID</th><th>Title</th><th>Tier</th><th>Category</th><th>Live Status</th></tr>
    {sc_rows}
  </table>

  <h2>🎓 Interview Prep (RCA Q&amp;A)</h2>
  <div class="sub" style="margin-bottom:0.5rem">Full troubleshooting / system-design / behavioral Q&amp;A per scenario — solve it first, then review. Compiled together in <code>docs/handbooks/interview-handbook.md</code>.</div>
  <table>
    <tr><th>Scenario</th><th>What it trains</th><th>Full Q&amp;A</th></tr>
    {qa_rows}
  </table>

  <footer>Not the real observability stack — that's Milestone 7 (Prometheus/Grafana). This is a lightweight, honest interim view: every status above is a live check, not simulated data.</footer>
</body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/", "/index.html"):
            self.send_response(404)
            self.end_headers()
            return
        body = build_html().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        pass  # keep the terminal quiet


def run_dashboard(port: int = 4000, open_browser: bool = True) -> None:
    url = f"http://localhost:{port}"
    print(f"Dashboard running at {url} (Ctrl+C to stop)")
    if open_browser:
        webbrowser.open(url)
    with socketserver.TCPServer(("127.0.0.1", port), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nDashboard stopped.")
