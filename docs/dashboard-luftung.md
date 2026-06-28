# Dashboard: Lüftung (Analyse)

Zeitreihen-Dashboard zur **Wirkungskontrolle** der Helios-Steuerung (`url_path`: `/dashboard-luftung`, Sidebar: **Lüftung**).

YAML: [`dashboards/luftung.yaml`](../dashboards/luftung.yaml)

Steuerung & Not-Aus bleiben auf dem Haupt-Dashboard **Übersicht** → Lüftungszentrale.

## Zweck

- Prüfen, ob **Lüfterstufen** CO₂ in allen Räumen senken und (nachts) die **Innentemperatur** beeinflussen
- **Steuergrund über die Zeit** — wann lief die Lüftung wegen CO₂, Nacht-Kühlung, Radon oder Not-Aus?
- Zeitliche Korrelation: gleiche Achse bei 24-h-Graphen (untereinander), 7-Tage-Trends separat

## Design

| Kriterium | Umsetzung |
|-----------|-----------|
| Status | Mushroom (Glue-Method wie Übersicht) |
| Steuergrund Verlauf | `logbook` (Klartext) + `history-graph` (`sensor.luftung_grund_stufe`) |
| Verlauf | Built-in `history-graph` (24 h) und `statistics-graph` (7 Tage) |
| Räume | Alle vier Aranet-Standorte (EG, 1. OG, 2. OG Büro, 2. OG Schlafz.) |

## Blöcke (Reihenfolge)

1. **Aktuell** — Status, Soll/Ist-%, Haus-Max-CO₂, ΔT, CO₂ je Raum
2. **24 h — Steuergrund** — Logbuch (`sensor.luftung_status`) + Kurve Grund-Stufe + Soll-%
3. **24 h — Lüfter** — Ist vs. Soll
4. **24 h — CO₂** — alle Räume + Haus-Max
5. **24 h — Temperatur** — Räume; separat Außen/Zuluft/Abluft (Helios)
6. **24 h — Luftfeuchte** — alle Räume
7. **7 Tage** — Grund + Lüfter, CO₂, Temperatur (Räume + Außen)

## Entities

### Steuerstatus (Recorder)

| Entity | Rolle |
|--------|--------|
| `sensor.luftung_status` | Klartext-Grund (Logbuch) |
| `sensor.luftung_grund_stufe` | Numerischer Grund für Graphen (Legende im Attribut `legende`) |
| `sensor.luftung_ziel_prozent` | Soll-% |

**Grund-Stufen:** `0`=aus · `1–4`=CO₂ · `5`=Nacht-Kühlung · `6–7`=Radon · `-1`=Not-Aus

### Räume (Aranet)

| Raum | CO₂ | Temperatur | Luftfeuchte |
|------|-----|------------|-------------|
| EG Küche | `sensor.aranet4_02_kueche_carbon_dioxide` | `sensor.aranet4_02_kueche_temperature` | `sensor.aranet4_02_kueche_humidity` |
| 1. OG | `sensor.c9_46_fc_e8_90_d9_carbon_dioxide` | `sensor.c9_46_fc_e8_90_d9_temperature` | `sensor.c9_46_fc_e8_90_d9_humidity` |
| 2. OG Büro | `sensor.aranet4_01_arbeitszimmer_carbon_dioxide` | `sensor.aranet4_01_arbeitszimmer_temperature` | `sensor.aranet4_01_arbeitszimmer_humidity` |
| 2. OG Schlafz. | `sensor.db_04_e6_6d_44_0d_carbon_dioxide` | `sensor.db_04_e6_6d_44_0d_temperature` | `sensor.db_04_e6_6d_44_0d_humidity` |

### Helios / Haus

| Entity | Rolle |
|--------|--------|
| `sensor.house_max_co2` | CO₂ Haus-Max |
| `sensor.helios_fan_speed_percentage` | Lüfter Ist-% |
| `sensor.helios_outside_air_temperature` | Außenluft |
| `sensor.helios_supply_air_temperature` | Zuluft |
| `sensor.helios_extract_air_temperature` | Abluft |

## Lesen der Graphen

- **Steuergrund:** Logbuch zeigt Klartext; Kurve `grund_stufe` springt bei Grundwechsel (Tap auf Sensor → Legende).
- **CO₂:** Nach Lüfter-Anstieg sollten alle Raumkurven innerhalb von ca. 30–90 min fallen — Schlafzimmer oft am spätesten.
- **Temperatur:** Bei Nacht-Kühlung (`grund_stufe` = 5) sinken Innen-Temperaturen, wenn Außen kühler ist.

## Abhängigkeiten

- HACS: **Mushroom**, **card-mod** (Status-Block)
- Recorder (MariaDB)
- [`climate.md`](./climate.md) — Steuerlogik

## Test-Checkliste

1. Template neu laden oder Core-Neustart (`sensor.luftung_grund_stufe` vorhanden)
2. Sidebar **Lüftung** — Logbuch und Grund-Kurve zeigen Einträge
3. CO₂-/Temp-Graphen: vier Raumlinien sichtbar
4. Nach Lüfter-Lauf: CO₂-Kurven reagieren

## Siehe auch

- [`dashboard-uebersicht.md`](./dashboard-uebersicht.md) — Steuerung
- [`climate.md`](./climate.md) — Automationen & Schwellen
