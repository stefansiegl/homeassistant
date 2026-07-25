#!/usr/bin/env python3
"""Load live-audit module definitions from JSON manifest."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load_manifest(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, help="Path to live-audit-modules.json")
    parser.add_argument("--yaml", type=Path, help="Deprecated alias — use --manifest")
    parser.add_argument("--get", help="Module ID to fetch")
    parser.add_argument("--list", action="store_true", help="List module IDs")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    manifest_path = args.manifest or args.yaml
    if manifest_path is None:
        json_path = root / "manifests/live-audit-modules.json"
        yaml_path = root / "manifests/live-audit-modules.yaml"
        manifest_path = json_path if json_path.is_file() else yaml_path

    if manifest_path.suffix == ".yaml":
        print(
            "Fehler: YAML-Manifest ohne PyYAML — bitte manifests/live-audit-modules.json pflegen",
            file=sys.stderr,
        )
        return 1

    data = load_manifest(manifest_path.resolve())
    modules = data.get("modules", {})

    if args.list:
        print("\n".join(modules.keys()))
        return 0

    if args.get:
        mod = modules.get(args.get)
        if mod is None:
            print("null")
            return 1
        print(json.dumps(mod, ensure_ascii=False))
        return 0

    print(json.dumps(modules, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
