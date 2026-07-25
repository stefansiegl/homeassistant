# Befeuchter-Saison (Deerma JSQ2W)

Drei **Deerma-Luftbefeuchter** (EG, 1. OG, 2. OG) werden **im Sommer abgebaut** und **Herbst/Winter** wieder in Betrieb genommen. Home Assistant soll offline-Geräte in der Off-Saison **nicht** als Fehler melden — in der Heizsaison aber **schon**.

## Ziel

- Sommer: Geräte dürfen `unavailable` sein — keine Automationen, kein Dashboard-Lärm, kein Audit-Alarm
- Winter (Saison aktiv): fehlende/offline Befeuchter → Warnung, Push (über Haus-Warnungen), Audit meldet normal

## Steuerung

| Entity | Typ | Rolle |
|--------|-----|-------|
| `input_boolean.befeuchter_saison_aktiv` | input_boolean | **Saison-Schalter** — `on` = Befeuchter-Saison (Herbst/Winter), `off` = Sommer/abgebaut |
| `binary_sensor.befeuchter_nicht_erreichbar` | binary_sensor | `on` wenn Saison aktiv **und** mindestens ein `humidifier.deerma_*` `unavailable`/`unknown` |

**Initialwert:** `off` (Sommer 2026 — Geräte abgebaut).

**Umschalten:** Einstellungen → Helfer → „Befeuchter-Saison aktiv“ — oder Automation/Dashboard später ergänzen.

## Geräte (unverändert)

| Etage | humidifier | Wassermangel |
|-------|------------|--------------|
| EG (Küche) | `humidifier.deerma_jsq2w_a365_humidifier` | `binary_sensor.deerma_jsq2w_a365_water_shortage_fault` |
| 1. OG | `humidifier.deerma_jsq2w_7134_humidifier` | `binary_sensor.deerma_jsq2w_7134_water_shortage_fault` |
| 2. OG (Büro) | `humidifier.deerma_jsq2w_b6e0_humidifier` | `binary_sensor.deerma_jsq2w_b6e0_water_shortage_fault` |

## Verhalten bei Saison OFF

- Automation **`Klima: Intelligente Befeuchtung`** — läuft nicht
- Automation **`Klima: Warnung Wassertank leer`** — läuft nicht
- Automation **`Zentrales Wartungs-Management`** — Befeuchter-Reinigungs-Push unterdrückt (Lüfterfilter unverändert)
- Dashboard **Übersicht** — Befeuchter-Spalten + Wartungskarte „Befeuchter Reinigung“ ausgeblendet
- `binary_sensor.befeuchter_nicht_erreichbar` — immer `off`
- Live-Audit — Deerma-Entities bei `unavailable` **ignoriert**

## Verhalten bei Saison ON

- Alle obigen Automationen/Dashboard-Elemente aktiv wie bisher
- `binary_sensor.befeuchter_nicht_erreichbar` — `on` wenn Gerät fehlt/offline
- Check in **`sensor.haus_warnungen`** (siehe [`haus-warnungen.md`](./haus-warnungen.md))
- Live-Audit — Deerma-`unavailable` wie andere Entities **warnen**

## Randfälle

- **Neustart:** `unknown`/`unavailable` der Befeuchter ~5 Min nach Core-Start ist normal (Xiaomi-MIoT Discovery). In der Saison erst danach bewerten.
- **Teilweise offline:** Ein fehlendes Gerät reicht für `befeuchter_nicht_erreichbar` und Haus-Warnung.
- **Wassermangel vs. offline:** Wassermangel-Automation nur bei Saison ON; echte `water_shortage_fault` ≠ offline.

## UI

- Dashboard [`dashboard-uebersicht.md`](./dashboard-uebersicht.md) — Raumklima-Spalten Befeuchter/Wasser + Wartungskarte conditional
- Optional später: Saison-Toggle auf Übersicht oder Lüftungszentrale

## Abnahme

- [ ] `input_boolean.befeuchter_saison_aktiv` = off → keine Deerma-Automationen, Dashboard ohne Befeuchter-Spalten
- [ ] Saison on, Geräte abgebaut → `binary_sensor.befeuchter_nicht_erreichbar` = on, Eintrag in `sensor.haus_warnungen.liste`
- [ ] Saison on, Geräte eingeschaltet → Befeuchtung läuft, Wassermangel-Push funktioniert
- [ ] `bin/audit-live.sh --module core` — bei Saison off keine Deerma-unavailable-Warnungen

## Siehe auch

- [`climate.md`](./climate.md) — Lüftung (Befeuchtung ergänzt Delta-Steuerung, nicht in climate.md Detail)
- [`dashboard-uebersicht.md`](./dashboard-uebersicht.md)
