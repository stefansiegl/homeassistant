# Haushalt: Hebeanlage (Status & letzter Lauf)

Leistungsbasierte Erkennung über `sensor.steckdose_keller_hebeanlage_power` (Nous A1Z / Zigbee2MQTT) und Status-Helper `input_select.hebeanlage_status_helper`.

## Ziel

- Dashboard (Übersicht) zeigt **standby / läuft** mit aktueller Leistung — analog Waschmaschine/Trockner
- Im Standby: **Zeitpunkt des letzten Pumpenlaufs** (`input_datetime.hebeanlage_letzter_lauf`)
- Kein „fertig“-Status (Pumpe zyklisch, kein Entleeren nötig)
- **Keine Push-Benachrichtigung** (Messung mit Nous A1Z ab 2026-06 verifiziert)

## Schwellen (V1, 2026-06-09)

| Übergang | Bedingung | Dauer |
|----------|-----------|-------|
| → `läuft` | Leistung **> 40 W** | 20 s |
| → `standby` | Leistung **< 15 W** | 1 Min |

**Hintergrund:** Jung-Steuerung im Leerlauf meldet **0 W**; laufende Tauchpumpe typisch **150–600 W** (kurze Zyklen).

## HA-Neustart während Pumpenlauf

Nach `homeassistant` start: 1 Min warten, dann Leistung prüfen:

- **> 40 W** → `läuft`
- **< 10 W** → `standby`
- dazwischen: Status unverändert

## Letzter Lauf

- Bei jedem Wechsel nach **`läuft`** (Leistung > 40 W, 20 s): `input_datetime.hebeanlage_letzter_lauf` auf `now()` setzen
- Dashboard-Kachel zeigt im Standby: `Zuletzt: DD.MM. HH:MM`

## YAML

| Datei | Inhalt |
|-------|--------|
| `helpers.yaml` | `input_select.hebeanlage_status_helper`, `input_datetime.hebeanlage_letzter_lauf` |
| `automations.yaml` | `hebeanlage_status_mgmt` |
| `dashboards/uebersicht.yaml` | Kachel Haushalt (4. Spalte) |

## Energie-Dashboard

`sensor.steckdose_keller_hebeanlage_energy` manuell unter **Einstellungen → Energie → Einzelgeräte** eintragen (UI, nicht `.storage` per Agent).

## Abnahme

1. Pumpenlauf (Regen / Wasser im Schacht) → Helper `läuft`, Kachel zeigt Leistung
2. Nach Zyklusende → Helper `standby`, Kachel zeigt **Zuletzt: …**
3. Kein Push bei Pumpenlauf
