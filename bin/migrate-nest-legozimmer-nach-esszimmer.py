#!/usr/bin/env python3
"""Einmal-Migration: Nest Legozimmer → Esszimmer + TTS-Gruppe. HA Core sollte gestoppt sein."""

from __future__ import annotations

import json
import sys
from pathlib import Path

CONFIG = Path("/root/config")
STORAGE = CONFIG / ".storage"

RENAMES = [
    # Keller-Powercalc war fälschlich „esszimmer“ benannt — zuerst freigeben
    ("sensor.nest_mini_esszimmer_power", "sensor.nest_mini_keller_power"),
    ("sensor.nest_mini_esszimmer_energy", "sensor.nest_mini_keller_energy"),
    # Legozimmer-Nest → Esszimmer
    ("sensor.nestmini3206_power", "sensor.nest_mini_esszimmer_power"),
    ("sensor.nestmini3206_energy", "sensor.nest_mini_esszimmer_energy"),
    ("media_player.nest_mini_legozimmer_raw", "media_player.nest_mini_esszimmer_raw"),
    ("media_player.legozimmer_1og", "media_player.nest_mini_esszimmer"),
    (
        "button.legozimmer_1_og_aktuellen_titel_favorisieren",
        "button.nest_mini_esszimmer_aktuellen_titel_favorisieren",
    ),
]

DEVICE_IDS_LEGO_NEST = ("7d049daf927673dcc720a4b3782602f8", "50095fb914adce4301e82f82e1347966")
BENACHRICHTIGUNG_GROUP = "01KHM2ATR53W6Y640T48M53NYB"
ALLE_LAUTSPRECHER_GROUP = "01KHKKSAFN40WHCZTXEP8BPGXR"
POWERCALC_KELLER = "f4f48250af89455ef3e1cedfb78a85b6"
POWERCALC_ESSZIMMER = "97db532f750b1598154d2ad0c0868ac6"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def rename_in_obj(obj, renames: dict[str, str]) -> None:
    if isinstance(obj, dict):
        for k, v in list(obj.items()):
            if isinstance(v, str) and v in renames:
                obj[k] = renames[v]
            else:
                rename_in_obj(v, renames)
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            if isinstance(item, str) and item in renames:
                obj[i] = renames[item]
            else:
                rename_in_obj(item, renames)


def migrate_entity_registry(path: Path, renames: dict[str, str]) -> int:
    data = load_json(path)
    count = 0
    for ent in data.get("data", {}).get("entities", []):
        old = ent.get("entity_id")
        if old in renames:
            ent["entity_id"] = renames[old]
            ent["previous_unique_id"] = old
            count += 1
        if old == "media_player.legozimmer_1og":
            ent["object_id_base"] = "nest_mini_esszimmer"
    save_json(path, data)
    return count


def migrate_device_registry(path: Path) -> None:
    data = load_json(path)
    for dev in data.get("data", {}).get("devices", []):
        if dev.get("id") in DEVICE_IDS_LEGO_NEST:
            dev["area_id"] = "esszimmer"
            dev["name"] = "Nest Mini Esszimmer"
    save_json(path, data)


def migrate_config_entries(path: Path, renames: dict[str, str]) -> None:
    data = load_json(path)
    for entry in data.get("data", {}).get("entries", []):
        eid = entry.get("entry_id")
        if eid == BENACHRICHTIGUNG_GROUP:
            entry["options"]["entities"] = ["media_player.nest_mini_esszimmer"]
        elif eid == ALLE_LAUTSPRECHER_GROUP:
            ents = entry["options"]["entities"]
            new_ents = []
            for e in ents:
                if e in renames:
                    e = renames[e]
                if e in ("media_player.nest_mini_legozimmer", "media_player.legozimmer_1og"):
                    e = "media_player.nest_mini_esszimmer"
                if e not in new_ents:
                    new_ents.append(e)
            entry["options"]["entities"] = new_ents
        elif eid == POWERCALC_KELLER:
            entry["title"] = "nest_mini_keller"
            entry["data"]["name"] = "nest_mini_keller"
            entry["data"]["_power_entity"] = "sensor.nest_mini_keller_power"
            entry["data"]["_energy_entity"] = "sensor.nest_mini_keller_energy"
        elif eid == POWERCALC_ESSZIMMER:
            entry["title"] = "nest_mini_esszimmer"
            entry["data"]["name"] = "nest_mini_esszimmer"
            entry["data"]["entity_id"] = "media_player.nest_mini_esszimmer_raw"
            entry["data"]["_power_entity"] = "sensor.nest_mini_esszimmer_power"
            entry["data"]["_energy_entity"] = "sensor.nest_mini_esszimmer_energy"
        rename_in_obj(entry, renames)
    save_json(path, data)


def main() -> int:
    renames = dict(RENAMES)
    reg_path = STORAGE / "core.entity_registry"
    n = migrate_entity_registry(reg_path, renames)
    migrate_device_registry(STORAGE / "core.device_registry")
    migrate_config_entries(STORAGE / "core.config_entries", renames)
    print(f"entity_registry: {n} entities renamed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
