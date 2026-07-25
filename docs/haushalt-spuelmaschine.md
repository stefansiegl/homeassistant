# Haushalt: Spülmaschine (Status & Benachrichtigung)

Leistungsbasierte Erkennung über `sensor.spuelmaschine_shellypro3em_leistung` (Shelly Pro 3EM, **Phase B — Herd + Spülmaschine am selben FI-Kreis**) und Status-Helper `input_select.spuelmaschine_status_helper`.

## Ziel

- Dashboard zeigt **standby / läuft / fertig**
- Push bei **läuft → fertig** nur nach echtem Spülgang
- **Kein Fehlalarm durch Induktionsherd** auf derselben Phase (typisch ~1 kW PWM, dazwischen ~20 W Spülmaschinen-Standby)

## Messpunkt (wichtig)

| Entity | Bedeutung |
|--------|-----------|
| `sensor.spuelmaschine_shellypro3em_leistung` | Shelly Pro 3EM Phase B (nur diese Phase) |
| `sensor.herd_und_spuelmaschine_shellypro3em_leistung` | Summe aller Phasen — **nicht** für Status nutzen |

Phase B misst **Herd und Spülmaschine gemeinsam**. Ein längerer Kochvorgang kann die alte Logik (> 50 W / 2 Min) fälschlich als Spülgang werten; nach dem Kochen bleibt ~20 W Standby → später „fertig“ + Push ohne laufende Spülmaschine.

**Langfristig sauberer:** eigene Mess-Steckdose nur an der Spülmaschine (wie Waschmaschine/Trockner). Bis dahin: erweiterte Heuristik unten.

## Vorfall 2026-07-11 (Analyse)

| Zeit (CEST) | Leistung | Status |
|-------------|----------|--------|
| 08:47 | ~1 kW (Herd) | — |
| 08:49 | weiter PWM Herd/Standby ~20 W | → `läuft` (alte Schwelle) |
| 09:41–09:55 | nur ~20 W (niemand kocht) | noch `läuft` |
| 10:00 | < 6 W | → `fertig` + Push (Fehlalarm) |

## Schwellen (2026-07-11)

| Übergang | Bedingung | Dauer | Zweck |
|----------|-----------|-------|-------|
| → `läuft` | Leistung **> 200 W** | **5 Min** (durchgehend) | Herd-PWM bricht Kontinuität; Spülmaschinen-Heizphase hält länger |
| → `standby` (Abbruch) | Leistung **< 45 W**, nur wenn `läuft` | **12 Min** | Nach Herd-Kochen: nur Spülmaschinen-Standby (~20 W), kein echter Gang |
| → `fertig` | Leistung **< 6 W** (nur wenn `läuft`) | 5 Min | Programm wirklich aus |
| → `standby` | Leistung **< 1 W** | 15 Min | Kreis komplett aus |

## YAML

| Datei | Inhalt |
|-------|--------|
| `helpers.yaml` | `input_select.spuelmaschine_status_helper` |
| `automations.yaml` | `1770730843209` (Status), `1770730888979` (Benachrichtigung) |
| `dashboards/uebersicht.yaml` | Kachel Haushalt |

## Abnahme

1. **Herd kochen, Spülmaschine aus** → kein Push; höchstens kurz `läuft`, dann `standby` (Abbruch nach ~12 Min Ruhe)
2. **Echter Spülgang** → `läuft` (nach ~5 Min Heizphase > 200 W), danach `fertig` + Push
3. **Ruhe über Nacht** → `standby`, keine Benachrichtigung
