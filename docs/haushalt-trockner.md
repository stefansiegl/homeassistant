# Haushalt: Trockner (Status & Benachrichtigung)

Leistungsbasierte Erkennung über `sensor.shellyplug_4_trockner_power` (Shelly Plug) und Status-Helper `input_select.trockner_status_helper`.

## Ziel

- Dashboard zeigt **standby / läuft / fertig** zuverlässig
- Push (`notify.mobile_app_pixel_9_pro`) bei **läuft → fertig**
- Optional TTS über `media_player.benachrichtigung_lautsprecher` (nur zu kinderfreundlichen Zeiten)

## Schwellen (V10, 2026-06-08)

| Übergang | Bedingung | Dauer |
|----------|-----------|-------|
| → `läuft` | Leistung **> 10 W** | 1 Min |
| → `fertig` | Leistung **< 6 W** (nur wenn Status `läuft`) | **3 Min** |
| → `standby` | Leistung **< 1 W** | 10 Min |

**Unterschied zur Waschmaschine:** Beim Trocknen liegt die Leistung bei **300–800 W**; nach Programmende fällt sie auf **~0 W** (nicht ~4 W wie bei der Waschmaschine). Deshalb reicht für `fertig` eine kürzere Wartezeit (**3 Min** statt 5 Min). Die Schwelle **6 W** ist gegenüber der Waschmaschine eher großzügig, deckt aber kurze Nachläufe ab.

## HA-Neustart während Trocknung

Nach `homeassistant` start: 1 Min warten, dann Leistung prüfen:

- **> 10 W** → `läuft`
- **< 1 W** → `standby`
- dazwischen: Status unverändert lassen

Gleiche Logik wie bei der Waschmaschine (V10) — ohne den `läuft`-Zweig bleibt der Helper nach Neustart auf `standby`, obwohl der Trockner läuft.

## YAML

| Datei | Inhalt |
|-------|--------|
| `helpers.yaml` | `input_select.trockner_status_helper` |
| `automations.yaml` | `trockner_status_mgmt`, `trockner_notify` |
| `dashboards/uebersicht.yaml` | Kachel Haushalt |

## Abnahme

1. Trocknung starten → Helper `läuft`
2. Nach Programmende (3 Min < 6 W) → `fertig` + Push
3. Nach Neustart während hoher Leistung → Helper wieder `läuft`
