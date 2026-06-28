# Haushalt: Spülmaschine (Status & Benachrichtigung)

Leistungsbasierte Erkennung über `sensor.spuelmaschine_shellypro3em_leistung` (Shelly Pro 3EM, Phase B) und Status-Helper `input_select.spuelmaschine_status_helper`.

## Ziel

- Dashboard zeigt **standby / läuft / fertig**
- Push bei **läuft → fertig** nur nach echtem Spülgang
- Keine Fehlmeldung durch Leerlauf-Spikes (~15–25 W) am Messpunkt

## Schwellen (2026-06-22)

| Übergang | Bedingung | Dauer |
|----------|-----------|-------|
| → `läuft` | Leistung **> 50 W** | 2 Min |
| → `fertig` | Leistung **< 6 W** (nur wenn Status `läuft`) | 5 Min |
| → `standby` | Leistung **< 1 W** | 15 Min |

**Hintergrund:** Mit `above: 5` reagierte die Automation auf kurze Restleistung (~13 W) ohne echten Heiz-/Spülgang. Waschmaschine nutzt analog **> 10 W** Start und **< 6 W** Fertig — Spülmaschine braucht höheren Start (50 W), weil der Shelly 3EM am Küchenkreis hängt.

## YAML

| Datei | Inhalt |
|-------|--------|
| `helpers.yaml` | `input_select.spuelmaschine_status_helper` |
| `automations.yaml` | `1770730843209` (Status), `1770730888979` (Benachrichtigung) |
| `dashboards/uebersicht.yaml` | Kachel Haushalt |

## Abnahme

1. Spülgang starten → Helper `läuft` (nach ~2 Min > 50 W)
2. Nach Programmende → `fertig` + Push
3. Ohne Spülgang über mehrere Stunden → **kein** `läuft`/`fertig`
