#!/usr/bin/env python3
"""T0: ha core check + filtered HA log lines for live audit."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys

LINES = 500

# Transient AI-on-the-Edge OCR raw payloads (e.g. suffix "N") — siehe docs/ai-on-the-edge.md
TRANSIENT_LOG_PATTERNS = (
    re.compile(r"sensor\.gasmeter_raw.*non-numeric value", re.I),
    re.compile(r"sensor\.watermeter_raw.*non-numeric value", re.I),
)

# HA CLI: optional ANSI, timestamp, then log level before "(Thread)"
HA_LOG_LINE = re.compile(
    r"(?:\x1b\[[0-9;]*m)?"
    r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+"
    r" (?P<level>ERROR|WARNING|CRITICAL|INFO|DEBUG) "
)


def log_level(line: str) -> str | None:
    m = HA_LOG_LINE.search(line)
    return m.group("level") if m else None


def is_error_line(line: str) -> bool:
    level = log_level(line)
    if level not in ("ERROR", "CRITICAL"):
        return False
    return not any(p.search(line) for p in TRANSIENT_LOG_PATTERNS)


def is_warning_line(line: str) -> bool:
    return log_level(line) == "WARNING"


def run(cmd: list[str]) -> tuple[int, str]:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        out = (proc.stdout or "") + (proc.stderr or "")
        return proc.returncode, out
    except (subprocess.TimeoutExpired, FileNotFoundError) as exc:
        return 127, str(exc)


def main() -> int:
    findings: list[dict] = []
    log_errors = 0
    log_warnings = 0

    if shutil.which("ha"):
        code, out = run(["ha", "core", "check"])
        if code != 0:
            sample = " ".join(out.strip().splitlines()[-5:])
            findings.append(
                {
                    "severity": "fail",
                    "code": "HA_CORE_CHECK",
                    "entity": None,
                    "message": f"ha core check fehlgeschlagen: {sample[:400]}",
                }
            )

        code, log_out = run(["ha", "core", "logs", "-n", str(LINES)])
        if code == 0 and log_out:
            lines = log_out.splitlines()
            err_lines = [l for l in lines if is_error_line(l)]
            warn_lines = [l for l in lines if is_warning_line(l)]
            log_errors = len(err_lines)
            log_warnings = len(warn_lines)
            if log_errors:
                sample = " | ".join(err_lines[-3:])
                findings.append(
                    {
                        "severity": "warn",
                        "code": "HA_LOG_ERRORS",
                        "entity": None,
                        "message": f"Letzte {LINES} Log-Zeilen: {log_errors} ERROR — {sample[:400]}",
                    }
                )
            if log_warnings > 10:
                findings.append(
                    {
                        "severity": "info",
                        "code": "HA_LOG_WARNINGS",
                        "entity": None,
                        "message": f"Letzte {LINES} Log-Zeilen: {log_warnings} WARNING (Schwellwert >10)",
                    }
                )
    else:
        findings.append(
            {
                "severity": "warn",
                "code": "HA_CLI_MISSING",
                "entity": None,
                "message": "ha CLI nicht verfügbar — core check übersprungen",
            }
        )

    severities = {f["severity"] for f in findings}
    if "fail" in severities:
        status = "fail"
    elif "warn" in severities:
        status = "warn"
    else:
        status = "ok"

    result = {
        "status": status,
        "findings": findings,
        "stats": {"log_errors": log_errors, "log_warnings": log_warnings},
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
