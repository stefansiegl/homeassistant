# Haushalt: Waschmaschine (Status & Benachrichtigung)

Leistungsbasierte Erkennung über `sensor.shellyplug_6_waschmaschine_power` (Shelly Plug) und Status-Helper `input_select.waschmaschine_status_helper`.

## Ziel

- Dashboard zeigt **standby / läuft / fertig** zuverlässig
- Push (`notify.pixel_9_pro`) bei **läuft → fertig**
- Optional TTS über `media_player.benachrichtigung_lautsprecher` (Nest Mini Esszimmer — siehe [`benachrichtigung-lautsprecher.md`](benachrichtigung-lautsprecher.md))

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

## Offen: Home Connect

**Status (28.06.2026):** Core-Integration `home_connect` eingerichtet (Siemens WM4WH640), OAuth in HA ok — aber **keine nutzbaren Live-Daten**. Während mehrerer Waschgänge am 28.06. blieb `binary_sensor.waschmaschine_konnektivitat` durchgehend `off`, Fortschritt/Endzeit `unavailable`. Es fehlt ein Betriebszustand-Sensor (`OperationState`); vermutlich meldet die Maschine sich in der Cloud nicht als verbunden.

**Produktiv:** Shelly-Leistungserkennung (oben) — unverändert.

### Neu verbinden (Checkliste, manuell)

1. **Home-Connect-App:** Gerät online? Fortschritt sichtbar während Waschgang?
2. **Maschine:** Wi-Fi / Home Connect in den Geräteeinstellungen prüfen oder neu einrichten.
3. **HA:** `Einstellungen → Geräte & Dienste → Home Connect` — ggf. Eintrag entfernen und neu hinzufügen (OAuth), **während die Maschine eingeschaltet/läuft**.
4. **Abnahme HC:** `binary_sensor.waschmaschine_konnektivitat` → `on`; Betriebszustand-Sensor erscheint; Fortschritt/Endzeit aktualisieren sich beim Waschgang.
5. **Optional später:** Status-Automation von Shelly auf HC umstellen (erst wenn Schritt 4 stabil über mehrere Waschgänge).

**Nicht parallel:** `home_connect_alt` (HACS) ist installiert, aber ohne Config Entry — bei Neuversuch zuerst Core-Integration reparieren.
