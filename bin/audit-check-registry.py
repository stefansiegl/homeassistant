#!/usr/bin/env python3
"""Compare extracted entity IDs against HA entity registry and restore state."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

BAD_STATES = frozenset({"unavailable", "unknown"})
AUTOMATION_OFF = "off"
# Notify/shell_command are services — often absent from entity_registry
SERVICE_ONLY_DOMAINS = frozenset({"notify", "shell_command"})
DEERMA_PREFIXES = ("humidifier.deerma_", "binary_sensor.deerma_", "switch.deerma_")
SKIP_DISABLED_CONFIG_DOMAINS = frozenset({"ble_monitor", "ipp"})
BEFEUCHTER_SAISON_ENTITY = "input_boolean.befeuchter_saison_aktiv"
BEFEUCHTER_CHECK_ENTITY = "binary_sensor.befeuchter_nicht_erreichbar"


def is_deerma_entity(eid: str) -> bool:
    return any(eid.startswith(p) for p in DEERMA_PREFIXES)


def load_registry(path: Path) -> dict[str, dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    entities = data.get("data", {}).get("entities", [])
    return {e["entity_id"]: e for e in entities if "entity_id" in e}


def load_restore_state(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    states: dict[str, str] = {}
    for item in data.get("data", []):
        st = item.get("state") or {}
        eid = st.get("entity_id")
        if eid:
            states[eid] = st.get("state", "unknown")
    return states


def load_config_entries(path: Path) -> list[dict]:
    if not path.is_file():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return data.get("data", {}).get("entries", [])


def check_entities(
    entity_ids: list[str],
    registry: dict[str, dict],
    live_states: dict[str, str],
    known_issues: list[dict],
) -> tuple[list[dict], dict]:
    known_by_entity = {k["entity"]: k for k in known_issues if "entity" in k}
    befeuchter_saison_aktiv = live_states.get(BEFEUCHTER_SAISON_ENTITY) == "on"
    findings: list[dict] = []
    stats = {
        "entities_checked": len(entity_ids),
        "entities_missing": 0,
        "entities_unavailable": 0,
        "automations_off": 0,
        "entities_disabled": 0,
    }

    for eid in sorted(set(entity_ids)):
        domain = eid.split(".", 1)[0]
        if domain in SERVICE_ONLY_DOMAINS:
            continue
        if eid not in registry:
            findings.append(
                {
                    "severity": "fail",
                    "code": "ENTITY_MISSING",
                    "entity": eid,
                    "message": f"Entity {eid} nicht in core.entity_registry",
                }
            )
            stats["entities_missing"] += 1
            continue

        reg = registry[eid]
        if reg.get("disabled_by"):
            known = known_by_entity.get(eid)
            if known and known.get("code") == "ENTITY_DISABLED":
                findings.append(
                    {
                        "severity": known.get("severity", "info"),
                        "code": "ENTITY_DISABLED",
                        "entity": eid,
                        "message": known.get("note", f"Entity deaktiviert ({reg.get('disabled_by')})"),
                        "known_issue": True,
                    }
                )
            else:
                findings.append(
                    {
                        "severity": "warn",
                        "code": "ENTITY_DISABLED",
                        "entity": eid,
                        "message": f"Entity deaktiviert ({reg.get('disabled_by')})",
                    }
                )
            stats["entities_disabled"] += 1

        state = live_states.get(eid)
        if state is None:
            continue

        if eid.startswith("automation.") and state == AUTOMATION_OFF:
            findings.append(
                {
                    "severity": "fail",
                    "code": "AUTOMATION_OFF",
                    "entity": eid,
                    "message": f"Automation {eid} ist aus (state=off)",
                }
            )
            stats["automations_off"] += 1
            continue

        if state in BAD_STATES:
            if is_deerma_entity(eid) and not befeuchter_saison_aktiv:
                continue
            if eid == BEFEUCHTER_CHECK_ENTITY and not befeuchter_saison_aktiv:
                continue
            known = known_by_entity.get(eid)
            if known:
                findings.append(
                    {
                        "severity": known.get("severity", "warn"),
                        "code": known.get("code", "ENTITY_UNAVAILABLE"),
                        "entity": eid,
                        "message": known.get("note", f"State={state} (bekanntes Issue)"),
                        "known_issue": True,
                    }
                )
            else:
                findings.append(
                    {
                        "severity": "warn",
                        "code": "ENTITY_UNAVAILABLE",
                        "entity": eid,
                        "message": f"Entity {eid} State={state}",
                    }
                )
            stats["entities_unavailable"] += 1

    return findings, stats


def check_disabled_config_entries(entries: list[dict], domains: list[str] | None = None) -> list[dict]:
    findings: list[dict] = []
    for entry in entries:
        if entry.get("disabled_by"):
            domain = entry.get("domain", "?")
            if domain in SKIP_DISABLED_CONFIG_DOMAINS:
                continue
            if domains and domain not in domains:
                continue
            findings.append(
                {
                    "severity": "warn",
                    "code": "CONFIG_ENTRY_DISABLED",
                    "entity": None,
                    "message": f"Config Entry '{entry.get('title', domain)}' ({domain}) deaktiviert",
                }
            )
    return findings


def overall_status(findings: list[dict]) -> str:
    severities = {f["severity"] for f in findings}
    if "fail" in severities:
        return "fail"
    if "warn" in severities:
        return "warn"
    return "ok"


def main() -> int:
    parser = argparse.ArgumentParser(description="Check entities against HA registry")
    parser.add_argument("--root", default="/config", type=Path)
    parser.add_argument("--entities-json", required=True, type=Path, help="Output from audit-extract-entities.py")
    parser.add_argument("--known-issues", default="[]", help="JSON array of known issue objects")
    parser.add_argument("--check-config-entries", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    extracted = json.loads(args.entities_json.read_text(encoding="utf-8"))
    known_issues = json.loads(args.known_issues)

    registry = load_registry(root / ".storage/core.entity_registry")
    live_states = load_restore_state(root / ".storage/core.restore_state")

    findings, stats = check_entities(
        extracted.get("entities", []),
        registry,
        live_states,
        known_issues,
    )

    if args.check_config_entries:
        entries = load_config_entries(root / ".storage/core.config_entries")
        findings.extend(check_disabled_config_entries(entries))

    for finding in findings:
        # attach source doc if entity appears in by_source
        eid = finding.get("entity")
        if eid and "source" not in finding:
            for src, ids in extracted.get("by_source", {}).items():
                if eid in ids:
                    finding["source"] = src
                    break

    result = {
        "status": overall_status(findings),
        "findings": findings,
        "stats": stats,
    }

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"status: {result['status']}")
        for f in findings:
            print(f"[{f['severity']}] {f.get('entity', '-')} {f['code']}: {f['message']}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
