#!/usr/bin/env python3
"""Extract Home Assistant entity_id references from markdown specs and YAML files."""

from __future__ import annotations

import argparse
import glob
import json
import re
import sys
from pathlib import Path

# domain.object_id — common HA entity pattern
ENTITY_RE = re.compile(
    r"\b("
    r"(?:automation|binary_sensor|button|camera|climate|cover|device_tracker|"
    r"fan|group|input_boolean|input_datetime|input_number|input_select|input_text|"
    r"light|lock|media_player|notify|number|person|scene|script|select|sensor|"
    r"switch|timer|update|vacuum|valve|weather|zone)"
    r"\.[a-z0-9_]+"
    r")\b"
)

# YAML keys that hold entity references
YAML_ENTITY_KEYS = (
    "entity_id",
    "entities",
    "target",
    "device_id",
    "area_id",
)

# Known HA service actions (not entity object_ids)
SERVICE_ACTIONS = frozenset({
    "turn_on", "turn_off", "toggle", "open", "close",
    "open_cover", "close_cover", "stop_cover",
    "set_value", "set_datetime", "increment", "decrement",
    "select_option", "select_next", "select_first", "select_last",
    "play_media", "volume_set", "volume_up", "volume_down", "media_play",
    "set_percentage", "set_speed", "set_hvac_mode", "set_temperature",
    "reload", "restart", "stop", "start", "trigger", "apply",
    "close_valve", "open_valve", "say", "customize", "resources",
})

NON_ENTITY_DOMAINS = frozenset({
    "homeassistant", "lovelace", "tts", "recorder", "shell_command",
    "powercalc", "statistics", "cost", "val", "this",  # SQL/Jinja aliases, not HA entities
})
FILE_EXTENSIONS = frozenset({".jpg", ".jpeg", ".png", ".webp", ".ini", ".yaml", ".md", ".json", ".sh"})

# Domains that are almost always services when paired with SERVICE_ACTIONS
SERVICE_HEAVY_DOMAINS = frozenset({
    "light", "switch", "cover", "fan", "climate", "lock", "script",
    "automation", "input_number", "input_select", "input_datetime",
    "input_boolean", "input_text", "media_player", "notify", "scene",
    "button", "number", "select", "vacuum", "valve",
})


def _is_entity(token: str) -> bool:
    if any(token.endswith(ext) for ext in FILE_EXTENSIONS):
        return False
    if token.endswith("_"):
        return False
    if token.count(".") != 1:
        return False
    domain, obj = token.split(".", 1)
    if domain in NON_ENTITY_DOMAINS:
        return False
    if not obj or obj.startswith("_") or obj.endswith("_"):
        return False
    if len(obj) < 3:
        return False
    if obj in SERVICE_ACTIONS:
        return False
    if domain in SERVICE_HEAVY_DOMAINS and obj in SERVICE_ACTIONS:
        return False
    # service-like: domain.verb_phrase that's a known action
    if domain in SERVICE_HEAVY_DOMAINS and any(
        obj.startswith(a + "_") or obj == a for a in SERVICE_ACTIONS
    ):
        return False
    return bool(re.match(r"^[a-z][a-z0-9_]*$", domain)) and bool(
        re.match(r"^[a-z0-9_]+$", obj)
    )


def extract_from_text(text: str, *, backtick_only: bool = False) -> set[str]:
    found: set[str] = set()
    if backtick_only:
        for match in re.finditer(r"`([a-z][a-z0-9_]*\.[a-z0-9_]+)`", text):
            token = match.group(1)
            if _is_entity(token):
                found.add(token)
        return found
    for match in ENTITY_RE.finditer(text):
        token = match.group(1)
        if _is_entity(token):
            found.add(token)
    return found


def extract_from_yaml_file(path: Path) -> set[str]:
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError as exc:
        print(f"warn: cannot read {path}: {exc}", file=sys.stderr)
        return set()
    found: set[str] = set()
    in_exclude_block = False
    exclude_indent = 0
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        if re.match(r"exclude\s*:", stripped):
            in_exclude_block = True
            exclude_indent = indent
            continue
        if in_exclude_block:
            if indent <= exclude_indent and not stripped.startswith("-"):
                in_exclude_block = False
            else:
                continue
        if stripped.startswith("service:") or stripped.startswith("- service:"):
            continue
        if "action:" in stripped or ".sh" in stripped or "*" in stripped:
            continue
        if stripped.startswith("unique_id:") or stripped.startswith("object_id:"):
            continue
        found.update(extract_from_text(line))
    return found


def collect_paths(root: Path, spec_globs: list[str], yaml_globs: list[str]) -> tuple[list[Path], list[Path]]:
    spec_paths: list[Path] = []
    yaml_paths: list[Path] = []

    for pattern in spec_globs:
        for p in sorted(root.glob(pattern)):
            if p.is_file():
                spec_paths.append(p)

    for pattern in yaml_globs:
        if pattern.startswith("dashboards/"):
            for p in sorted(root.glob(pattern)):
                if p.is_file():
                    yaml_paths.append(p)
        else:
            candidate = root / pattern
            if candidate.is_file():
                yaml_paths.append(candidate)
            else:
                for p in sorted(root.glob(pattern)):
                    if p.is_file():
                        yaml_paths.append(p)

    return spec_paths, yaml_paths


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract entity IDs for live audit")
    parser.add_argument("--root", default="/config", type=Path)
    parser.add_argument("--spec", action="append", default=[], help="Spec path glob relative to root")
    parser.add_argument("--yaml", action="append", default=[], help="YAML path relative to root")
    parser.add_argument("--json", action="store_true", help="Output JSON")
    args = parser.parse_args()

    root = args.root.resolve()
    spec_paths, yaml_paths = collect_paths(root, args.spec, args.yaml)

    by_source: dict[str, list[str]] = {}
    all_entities: set[str] = set()

    for path in spec_paths:
        rel = str(path.relative_to(root))
        entities = sorted(
            extract_from_text(
                path.read_text(encoding="utf-8", errors="replace"),
                backtick_only=True,
            )
        )
        if entities:
            by_source[rel] = entities
            all_entities.update(entities)

    for path in yaml_paths:
        rel = str(path.relative_to(root))
        entities = sorted(extract_from_yaml_file(path))
        if entities:
            existing = by_source.get(rel, [])
            merged = sorted(set(existing) | set(entities))
            by_source[rel] = merged
            all_entities.update(entities)

    result = {
        "entities": sorted(all_entities),
        "by_source": by_source,
        "spec_files": [str(p.relative_to(root)) for p in spec_paths],
        "yaml_files": [str(p.relative_to(root)) for p in yaml_paths],
        "count": len(all_entities),
    }

    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        for eid in result["entities"]:
            print(eid)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
