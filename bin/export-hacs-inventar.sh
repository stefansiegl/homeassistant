#!/usr/bin/env bash
# Exportiert HACS-Inventar → JSON + docs/hacs-inventar.md (Tabellen automatisch)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_JSON="$ROOT/manifests/hacs-inventar.json"
OUT_MD="$ROOT/docs/hacs-inventar.md"
HACS_REPOS="$ROOT/.storage/hacs.repositories"
LOVELACE_RES="$ROOT/.storage/lovelace_resources"
CONFIG_ENTRIES="$ROOT/.storage/core.config_entries"
DATE="$(date +%Y-%m-%d)"

if [[ ! -f "$HACS_REPOS" ]]; then
  echo "Fehler: $HACS_REPOS nicht gefunden" >&2
  exit 1
fi

mkdir -p "$ROOT/manifests"

jq -n \
  --arg date "$DATE" \
  --slurpfile repos "$HACS_REPOS" \
  --slurpfile resources "${LOVELACE_RES}" \
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
    source: "hacs.repositories + lovelace_resources + core.config_entries",
    hacs_installed: ($installed | sort_by(.category, .repository)),
    lovelace_resources: $lovelace,
    note: "custom_components/ und www/community/ stehen absichtlich nicht in Git — siehe docs/konfigurations-strategie.md"
  }
  ' > "$OUT_JSON"

integration_status() {
  local domain="$1"
  case "$domain" in
    grocy) echo "❌ deprecated, nicht genutzt"; return ;;
    helios) echo "❌ installiert, kein Config Entry (→ easycontrols)"; return ;;
    home_connect_alt) echo "❌ installiert, kein Config Entry"; return ;;
    gruenbeck_cloud) echo "❌ installiert, kein Config Entry"; return ;;
    hacs) echo "✅"; return ;;
  esac

  if [[ ! -f "$CONFIG_ENTRIES" ]]; then
    echo "?"
    return
  fi

  local result
  result="$(jq -r --arg d "$domain" '
    [.data.entries[] | select(.domain == $d)] |
    if length == 0 then "missing"
    elif any(.disabled_by != null) then "disabled"
    else "active" end
  ' "$CONFIG_ENTRIES")"

  case "$result" in
    active)
      case "$domain" in
        ms365_todo) echo "✅ To Do" ;;
        easycontrols) echo "✅ Helios KWL" ;;
        powercalc) echo "✅ (viele Geräte)" ;;
        waste_collection_schedule) echo "✅ Müll" ;;
        nuki_ng) echo "✅ Haustür" ;;
        gardena_smart_system) echo "✅ (Integration vorhanden)" ;;
        *) echo "✅" ;;
      esac
      ;;
    disabled) echo "⏸ deaktiviert" ;;
    missing) echo "❌ installiert, kein Config Entry" ;;
    *) echo "?" ;;
  esac
}

{
  cat <<EOF
# HACS-Inventar

Snapshot der **installierten HACS-Komponenten** — für Neuinstallation, Abgleich und Disaster Recovery.

**Maschinenlesbar:** [\`manifests/hacs-inventar.json\`](../manifests/hacs-inventar.json)  
**Aktualisieren:** \`bin/hacs-abgleich.sh\` (Export + optional Git-Commit/Push)

**Stand:** ${DATE} *(automatisch generiert)*

---

## Was in Git liegt — und was nicht

| In Git | Nicht in Git (\`.gitignore\`) |
|--------|----------------------------|
| Dieses Inventar + JSON-Snapshot | \`custom_components/\` (HACS-Code) |
| Lovelace-Ressourcen in \`configuration.yaml\` | \`www/community/\` (Frontend-JS) |
| Dashboard-YAML, Automationen | HACS-UI-Zustand (\`.storage/hacs.*\`) |
| Specs in \`docs/integrationen-und-addons.md\` | OAuth-Tokens, Config-Entry-Daten |

**Kurz:** Git dokumentiert *was* installiert ist und *wie* es eingebunden wird. Den **Code** holt HACS nach Restore erneut — siehe Abschnitt „Neuinstallation“.

---

## Integrationen (HACS)

| Domain | Repository | Version | In HA konfiguriert |
|--------|------------|---------|-------------------|
EOF

  jq -r '.hacs_installed[] | select(.category == "integration") | [.domain // "?", .repository, .version] | @tsv' "$OUT_JSON" |
    while IFS=$'\t' read -r domain repo ver; do
      status="$(integration_status "$domain")"
      printf '| `%s` | %s | %s | %s |\n' "$domain" "$repo" "$ver" "$status"
    done

  cat <<'EOF'

---

## Frontend (Lovelace-Karten & Theme)

| Typ | Repository | Version | Registriert |
|-----|------------|---------|-------------|
EOF

  jq -r '.hacs_installed[] | select(.category == "plugin" or .category == "theme") | [.category, .repository, .version] | @tsv' "$OUT_JSON" |
    while IFS=$'\t' read -r typ repo ver; do
      reg="✅"
      if [[ "$typ" == "theme" ]]; then reg="HACS (Theme-Auswahl UI)"; else reg="✅ \`.storage\` + \`configuration.yaml\`"; fi
      printf '| %s | %s | %s | %s |\n' "$typ" "$repo" "$ver" "$reg"
    done

  cat <<'EOF'

**Lovelace-Ressourcen** (aus `.storage/lovelace_resources`):

EOF

  jq -r '.lovelace_resources[]?.url // empty' "$OUT_JSON" | while read -r url; do
    base="${url%%\?*}"
    echo "- \`${base}\`"
  done

  cat <<'EOF'

---

## Regelmäßiger Abgleich

| Was | Wie |
|-----|-----|
| **Automatisch** | Cron Sonntag 06:00 — `bin/hacs-abgleich.sh --push` (Commit nur bei Änderungen) |
| **Manuell** | `bin/hacs-abgleich.sh --push` nach HACS-Updates |
| **Nur Export** | `bin/export-hacs-inventar.sh` |

Log: `log/hacs-abgleich.log`

---

## Neuinstallation / Restore

1. **HA-Backup restore** (empfohlen) — enthält `custom_components/`, `www/community/`, HACS-State.
2. **Ohne Backup, nur Git:**
   - HACS installieren → Integrationen/Plugins **aus dieser Liste** erneut laden (gleiche Repos + Versionen).
   - Lovelace-Ressourcen: in HA UI **oder** aus `configuration.yaml` → `lovelace.resources` (bei `mode: storage` zusätzlich in UI registrieren).
   - Integrationen in UI neu verknüpfen (OAuth, API-Keys → `secrets.yaml`).
3. Nach HACS-Änderungen: **`bin/hacs-abgleich.sh --push`**.

---

## Aufräum-Kandidaten (optional)

- `grocy` — laut [`integrationen-und-addons.md`](integrationen-und-addons.md) deprecated
- `helios` — falls nur `easycontrols` genutzt wird
- `home_connect_alt`, `gruenbeck_cloud` — installiert ohne Config Entry

Entfernen nur nach Prüfung in HACS/HA, ob wirklich ungenutzt.

---

## Referenzen

- [`konfigurations-strategie.md`](konfigurations-strategie.md) — YAML vs. UI, `custom_components/` in Gitignore
- [`integrationen-und-addons.md`](integrationen-und-addons.md) — Setup-Notizen pro Integration
EOF
} > "$OUT_MD"

echo "Geschrieben: $OUT_JSON"
echo "Geschrieben: $OUT_MD"
