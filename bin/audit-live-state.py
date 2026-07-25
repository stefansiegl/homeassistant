#!/usr/bin/env python3
"""Manage live-audit state manifest (resume / reset / update)."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")


def load_state(path: Path) -> dict:
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    return {
        "version": 1,
        "cycle_started": None,
        "cycle_complete": False,
        "last_run": None,
        "module_order": [],
        "modules": {},
    }


def save_state(path: Path, state: dict) -> None:
    path.write_text(json.dumps(state, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def next_pending(state: dict) -> str | None:
    order = state.get("module_order", [])
    modules = state.get("modules", {})
    for mid in order:
        if modules.get(mid, {}).get("status") == "pending":
            return mid
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--next", action="store_true", help="Print next pending module ID")
    parser.add_argument("--reset", action="store_true", help="Reset cycle to pending")
    parser.add_argument("--update", action="store_true")
    parser.add_argument("--module")
    parser.add_argument("--status")
    parser.add_argument("--tier", type=int, default=0)
    parser.add_argument("--findings-count", type=int, default=0)
    parser.add_argument("--report")
    args = parser.parse_args()

    path = args.state.resolve()
    state = load_state(path)

    if args.reset:
        ts = now_iso()
        state["cycle_started"] = ts
        state["cycle_complete"] = False
        state["last_run"] = None
        for mid in state.get("modules", {}):
            state["modules"][mid] = {
                "status": "pending",
                "last_run": None,
                "tier_completed": 0,
                "findings_count": 0,
                "last_report": None,
            }
        save_state(path, state)
        return 0

    if args.next:
        nxt = next_pending(state)
        if nxt is None:
            state["cycle_complete"] = True
            save_state(path, state)
            print("COMPLETE")
        else:
            print(nxt)
        return 0

    if args.update:
        if not args.module or not args.status:
            print("error: --module and --status required for --update", file=__import__("sys").stderr)
            return 1
        ts = now_iso()
        if state.get("cycle_started") is None:
            state["cycle_started"] = ts
        state["last_run"] = ts
        state["cycle_complete"] = False
        mod = state.setdefault("modules", {}).setdefault(args.module, {})
        mod["status"] = args.status
        mod["last_run"] = ts
        mod["tier_completed"] = args.tier
        mod["findings_count"] = args.findings_count
        if args.report:
            mod["last_report"] = args.report
        # check if all non-pending
        order = state.get("module_order", list(state.get("modules", {}).keys()))
        pending = [m for m in order if state["modules"].get(m, {}).get("status") == "pending"]
        if not pending:
            state["cycle_complete"] = True
        save_state(path, state)
        return 0

    print(json.dumps(state, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
