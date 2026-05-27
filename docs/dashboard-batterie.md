# Dashboard: Batterie

Übersicht aller **Sender-Batterien** (Knopfzellen etc.) im Haus (`url_path`: `/dashboard-battery`, Sidebar: **Batterie**).

YAML: [`dashboards/batterie.yaml`](../dashboards/batterie.yaml)

## Zweck

- Welche Geräte melden niedrigen Batteriestand?
- **Nuki Haustür** zuerst — Zugang zum Haus darf nicht ausgehen
- Keine Handys/Tablets (wiederaufladbare Geräte)

## Design (Glue + Mushroom)

Orientierung: [`standards.md`](./standards.md), Referenz-Layout [`dashboards/uebersicht.yaml`](../dashboards/uebersicht.yaml)

| Kriterium | Umsetzung |
|-----------|-----------|
| Nur Mushroom | `custom:mushroom-*`, kein Markdown/button-card |
| Glue-Method | `vertical-stack` + `mushroom-title-card` + `card_mod` (Rahmen verbunden, kein Schatten) |
| Kritische Info zuerst | Block 1 Nuki → Block 2 Bald leer → Block 3 Alle |
| Ampel | `icon_color`: rot unter Schwelle, orange 25–40 %, grün darüber |
| Dynamik | Listen via `sensor.batterie_ubersicht` (Backend-Template), Anzeige in `mushroom-template-card` |

## Datenquelle

- **`sensor.batterie_ubersicht`** in [`configuration.yaml`](../configuration.yaml) — berechnet gefilterte Listen serverseitig (HA slug aus „Batterie Uebersicht“)
- **State** = Gesamtanzahl (Zahl, HA-Limit 255 Zeichen); **Attribut** `liste_alle` = mehrzeilige Gesamtliste

## Filterregeln (Template)

- `states.sensor` mit `attributes.device_class == 'battery'`
- State numerisch 0–100, nicht `unavailable` / `unknown`
- **Ausgeschlossen:** Entity-ID enthält `pixel_` oder `tablett_` (Handys/Tablets)
- `binary_sensor` mit `device_class: battery` und `state: on` → zusätzlich in „Bald leer“

## Schwellwert

- `input_number.batterie_warnschwelle` (Start **25 %**) — Dashboard „Bald leer“ + Nuki-Push-Automation

## Blöcke (Reihenfolge)

1. **Haustür — Nuki** — `sensor.nuki_haustur_battery`, Critical-Sensoren, `lock.nuki_haustur_lock`
2. **Bald leer** — Geräte unter Schwelle, sortiert aufsteigend
3. **Alle Batterien** — Gesamtliste sortiert nach %

## Nuki-Entities

| Entity | Rolle |
|--------|--------|
| `sensor.nuki_haustur_battery` | Akku % Schloss |
| `binary_sensor.nuki_haustur_battery_critical` | Kritisch (Schloss) |
| `binary_sensor.nuki_haustur_keypad_battery_critical` | Kritisch (Keypad) |
| `lock.nuki_haustur_lock` | Status (Info) |

Push-Automation: `Nuki: Haustür Batterie warnen` in [`automations.yaml`](../automations.yaml)

## Abhängigkeiten

- HACS: **Mushroom**, **card-mod** (registriert in `configuration.yaml` → `lovelace.resources`)

## Test-Checkliste

1. Helfer neu laden → `input_number.batterie_warnschwelle` = 25
2. Template-Entitäten neu laden (oder Core-Neustart)
3. Core-Neustart (Dashboard-Registrierung)
3. Sidebar **Batterie**: drei Glue-Blöcke, optisch wie Übersicht
4. Nuki oben, Ampelfarben plausibel
5. Keine `pixel_*` / `tablett_*` in Listen
6. Push bei Nuki unter Schwelle / Critical (Developer Tools testen)

## Backlog

- [ ] HACS `auto-entities` für Einzelkarten pro Gerät (Phase 2)
- [ ] Generische Low-Battery-Automation (Blueprint sbyx)

## Siehe auch

- [`konfigurations-strategie.md`](./konfigurations-strategie.md)
- [`dashboard-uebersicht.md`](./dashboard-uebersicht.md)
- [`lights.md`](./lights.md) — Zigbee-Schalter-Batterien
