# HACS-Inventar

Snapshot der **installierten HACS-Komponenten** — für Neuinstallation, Abgleich und Disaster Recovery.

**Maschinenlesbar:** [`manifests/hacs-inventar.json`](../manifests/hacs-inventar.json)  
**Aktualisieren:** `bin/hacs-abgleich.sh` (Export + optional Git-Commit/Push)

**Stand:** 2026-07-05 *(automatisch generiert)*

---

## Was in Git liegt — und was nicht

| In Git | Nicht in Git (`.gitignore`) |
|--------|----------------------------|
| Dieses Inventar + JSON-Snapshot | `custom_components/` (HACS-Code) |
| Lovelace-Ressourcen in `configuration.yaml` | `www/community/` (Frontend-JS) |
| Dashboard-YAML, Automationen | HACS-UI-Zustand (`.storage/hacs.*`) |
| Specs in `docs/integrationen-und-addons.md` | OAuth-Tokens, Config-Entry-Daten |

**Kurz:** Git dokumentiert *was* installiert ist und *wie* es eingebunden wird. Den **Code** holt HACS nach Restore erneut — siehe Abschnitt „Neuinstallation“.

---

## Integrationen (HACS)

| Domain | Repository | Version | In HA konfiguriert |
|--------|------------|---------|-------------------|
| `ms365_todo` | RogerSelwyn/MS365-ToDo | v1.11.1 | ✅ To Do |
| `xiaomi_miot` | al-one/hass-xiaomi-miot | v1.1.4 | ✅ |
| `helios` | asev/homeassistant-helios | v0.5 | ❌ installiert, kein Config Entry (→ easycontrols) |
| `powercalc` | bramstroker/homeassistant-powercalc | v1.21.2 | ✅ (viele Geräte) |
| `ble_monitor` | custom-components/ble_monitor | 13.14.0 | ⏸ deaktiviert |
| `grocy` | custom-components/grocy | 2025.7.0 | ❌ deprecated, nicht genutzt |
| `home_connect_alt` | ekutner/home-connect-hass | 1.4.2 | ❌ installiert, kein Config Entry |
| `hacs` | hacs/integration | 2.0.5 | ✅ |
| `nuki_ng` | kvj/hass_nuki_ng | 0.5.5 | ✅ Haustür |
| `easycontrols` | laszlojakab/homeassistant-easycontrols | 0.7.0 | ✅ Helios KWL |
| `waste_collection_schedule` | mampfes/hacs_waste_collection_schedule | v2.29.0 | ✅ Müll |
| `gruenbeck_cloud` | p0l0/hagruenbeck_cloud | 1.0.5 | ❌ installiert, kein Config Entry |
| `gardena_smart_system` | py-smart-gardena/hass-gardena-smart-system | 3.1.3 | ✅ (Integration vorhanden) |

---

## Frontend (Lovelace-Karten & Theme)

| Typ | Repository | Version | Registriert |
|-----|------------|---------|-------------|
| plugin | NemesisRE/kiosk-mode | v14.0.1 | ✅ `.storage` + `configuration.yaml` |
| plugin | custom-cards/button-card | v7.0.1 | ✅ `.storage` + `configuration.yaml` |
| plugin | piitaya/lovelace-mushroom | v5.1.1 | ✅ `.storage` + `configuration.yaml` |
| plugin | thomasloven/lovelace-card-mod | v4.2.1 | ✅ `.storage` + `configuration.yaml` |
| theme | piitaya/lovelace-mushroom-themes | v0.0.11 | HACS (Theme-Auswahl UI) |

**Lovelace-Ressourcen** (aus `.storage/lovelace_resources`):

- `/hacsfiles/lovelace-mushroom/mushroom.js`
- `/hacsfiles/lovelace-card-mod/card-mod.js`
- `/hacsfiles/button-card/button-card.js`
- `/hacsfiles/kiosk-mode/kiosk-mode.js`

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
