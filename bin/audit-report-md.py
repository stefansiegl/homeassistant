#!/usr/bin/env python3
"""Render live-audit JSON report as Markdown."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def severity_icon(sev: str) -> str:
    return {"fail": "FAIL", "warn": "WARN", "info": "INFO"}.get(sev, sev.upper())


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: audit-report-md.py report.json", file=sys.stderr)
        return 1

    report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    lines = [
        f"# Live-Audit: {report.get('module_title', report.get('module', '?'))}",
        "",
        f"- **Run:** {report.get('run_id')}",
        f"- **Modul:** `{report.get('module')}`",
        f"- **Status:** **{report.get('status', '?').upper()}**",
        f"- **Tier:** T{report.get('tier_completed', 0)}",
        "",
    ]

    stats = report.get("stats") or {}
    if stats:
        lines.append("## Statistik")
        lines.append("")
        for k, v in stats.items():
            lines.append(f"- {k}: {v}")
        lines.append("")

    findings = report.get("findings") or []
    if not findings:
        lines.append("Keine Findings.")
    else:
        by_sev: dict[str, list] = {"fail": [], "warn": [], "info": []}
        for f in findings:
            by_sev.setdefault(f.get("severity", "info"), []).append(f)
        lines.append("## Findings")
        lines.append("")
        for sev in ("fail", "warn", "info"):
            items = by_sev.get(sev, [])
            if not items:
                continue
            lines.append(f"### {severity_icon(sev)} ({len(items)})")
            lines.append("")
            for f in items:
                ent = f.get("entity")
                ent_s = f"`{ent}`" if ent else "—"
                src = f.get("source")
                src_s = f" ({src})" if src else ""
                known = " [bekannt]" if f.get("known_issue") else ""
                lines.append(f"- **{f.get('code')}** {ent_s}{src_s}{known}: {f.get('message')}")
            lines.append("")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
