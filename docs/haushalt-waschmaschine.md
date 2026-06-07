# Haushalt: Waschmaschine (Status & Benachrichtigung)

Leistungsbasierte Erkennung über `sensor.shellyplug_6_waschmaschine_power` (Shelly Plug) und Status-Helper `input_select.waschmaschine_status_helper`.

## Ziel

- Dashboard zeigt **standby / läuft / fertig** zuverlässig
- Push (`notify.mobile_app_pixel_9_pro`) bei **läuft → fertig**
- Optional TTS über `media_player.benachrichtung_lautsprecher` (nur zu kinderfreundlichen Zeiten)

## Schwellen (V10, 2026-06-07)

| Übergang | Bedingung | Dauer |
|----------|-----------|-------|
| → `läuft` | Leistung **> 10 W** | 1 Min |
| → `fertig` | Leistung **< 6 W** (nur wenn Status `läuft`) | 5 Min |
| → `standby` | Leistung **< 1 W** | 10 Min |

**Hintergrund Fertig-Schwelle 6 W:** Im Programmende/Pause liegt die Restleistung oft bei ~4,0–4,2 W. Mit `below: 4` wurde `fertig` nie erkannt.

## HA-Neustart während Waschgang

Nach `homeassistant` start: 1 Min warten, dann Leistung prüfen:

- **> 10 W** → `läuft` (Maschine läuft noch, z. B. Schleuderphase)
- **< 1 W** → `standby`
- dazwischen: Status unverändert lassen

Ohne den `läuft`-Zweig blieb der Helper nach Neustart auf `standby`, obwohl die Maschine lief — dann kein Übergang `läuft` → `fertig` und **keine Push**.

## YAML

| Datei | Inhalt |
|-------|--------|
| `helpers.yaml` | `input_select.waschmaschine_status_helper` |
| `automations.yaml` | `waschmaschine_status_mgmt`, `waschmaschine_notify` |
| `dashboards/uebersicht.yaml` | Kachel Haushalt |

## Abnahme

1. Waschgang starten → Helper `läuft`
2. Nach Programmende (5 Min < 6 W) → `fertig` + Push
3. Nach Neustart während hoher Leistung → Helper wieder `läuft`
