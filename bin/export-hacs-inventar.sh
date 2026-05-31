#!/usr/bin/env bash
# Exportiert installierte HACS-Komponenten nach manifests/hacs-inventar.json
# und aktualisiert den Snapshot-Block in docs/hacs-inventar.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_JSON="$ROOT/manifests/hacs-inventar.json"
OUT_MD="$ROOT/docs/hacs-inventar.md"
HACS_REPOS="$ROOT/.storage/hacs.repositories"
LOVELACE_RES="$ROOT/.storage/lovelace_resources"
DATE="$(date +%Y-%m-%d)"

if [[ ! -f "$HACS_REPOS" ]]; then
  echo "Fehler: $HACS_REPOS nicht gefunden (HA .storage lesbar?)" >&2
  exit 1
fi

mkdir -p "$ROOT/manifests"

jq -n \
  --arg date "$DATE" \
  --slurpfile repos "$HACS_REPOS" \
  --slurpfile resources "$LOVELACE_RES" \
  '
  ($repos[0].data | to_entries | map(select(.value.installed == true)) | map({
    category: .value.category,
    repository: .value.full_name,
    domain: (.value.domain // null),
    version: (.value.last_version // .value.version // "?")
  })) as $installed |
  ($resources[0].data.items // []) as $lovelace |
  {
    snapshot_date: $date,
    source: "hacs.repositories + lovelace_resources + custom_components/manifest.json",
    hacs_installed: ($installed | sort_by(.category, .repository)),
    lovelace_resources: $lovelace,
    note: "custom_components/ und www/community/ stehen absichtlich nicht in Git — siehe docs/konfigurations-strategie.md"
  }
  ' > "$OUT_JSON"

echo "Geschrieben: $OUT_JSON"
echo "Bitte docs/hacs-inventar.md Tabellen manuell gegen JSON prüfen oder bei größeren HACS-Änderungen aktualisieren."
