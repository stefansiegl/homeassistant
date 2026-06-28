# Dashboard: Zählerstände

Übersicht der **aktuellen Zählerstände** für Meldungen an Versorger (`url_path`: `/dashboard-zaehlerstaende`, Sidebar: **Zählerstände**).

YAML: [`dashboards/zaehlerstaende.yaml`](../dashboards/zaehlerstaende.yaml)

## Zweck

- Gas, Wasser und Strom (OBIS **1.8.0** Bezug / **2.8.0** Einspeisung) auf einen Blick
- Werte zum Ablesen und Eintragen in Online-Portale der Stadtwerke / des Netzbetreibers
- Hinweis bei OCR-Problem, Offline oder gefiltertem Ausreißer

## Design

| Kriterium | Umsetzung |
|-----------|-----------|
| Cards | Mushroom + Glue-Method (wie Batterie / Lüftung) |
| Werte | **Stabil-Entities** (gefiltert, wie Energie-Dashboard) |
| Format | Deutsche Kommazahlen, passende Nachkommastellen |

## Entities (Meldewerte)

| Medium | Anzeige | Entity | Einheit |
|--------|---------|--------|---------|
| Gas | Zählerstand | `sensor.gasmeter_value_stabil` | m³ |
| Wasser | Zählerstand | `sensor.watermeter_value_stabil` | m³ |
| Strom Bezug | OBIS 1.8.0 | `sensor.mt691_total_in_stabil` | kWh |
| Strom Einspeisung | OBIS 2.8.0 | `sensor.mt691_total_out_stabil` | kWh |

**Nicht** die OCR-Rohwerte (`gasmeter_value`, `watermeter_value`) oder Tasmota-Roh-Entities für die Meldung nutzen — außer bei Störung und bewusstem Abgleich am physischen Zähler.

## Status / Warnungen

| Check | Entity |
|-------|--------|
| Gas Problem | `binary_sensor.gasmeter_problem`, `binary_sensor.gasmeter_warnung` |
| Wasser Problem | `binary_sensor.watermeter_problem`, `binary_sensor.watermeter_warnung` |
| Ausreißer gefiltert | Attribut `filtered: true` an `*_stabil` |
| Strom offline | `sensor.mt691_total_in_stabil` = `unavailable` |

Bei **Wasser/Gas OCR-Fehler:** Web-UI prüfen ([Wasser `.121`](http://192.168.188.121/), [Gas `.122`](http://192.168.188.122/)) oder physisch ablesen — siehe [`ai-on-the-edge.md`](./ai-on-the-edge.md).

Strom: ISKRA MT691 + Tasmota IR — siehe [`energie-statistik-praevention.md`](./energie-statistik-praevention.md).

## Gas — Stammdaten (Versorgerportal)

| Feld | Wert |
|------|------|
| Zählernummer | `7PIP0003662520` |
| Vertragsnummer | `795291806` |

Im Dashboard unter **Gas — Portal** zum Ablesen neben dem m³-Wert.

## Abnahme

- [ ] Sidebar **Zählerstände** sichtbar
- [ ] Vier Hauptwerte plausibel (Gas ~998x m³, Wasser ~150 m³, Strom kWh steigend)
- [ ] Sammelkarte zeigt alle Werte zum Kopieren
- [ ] Gas-Zählernummer und Vertragsnummer auf der Portal-Karte sichtbar
- [ ] Bei `problem` = on erscheint Warnhinweis auf der jeweiligen Karte

## Siehe auch

- [`ai-on-the-edge.md`](./ai-on-the-edge.md) — Gas/Wasser
- [`energie-statistik-praevention.md`](./energie-statistik-praevention.md) — Strom stabil
- [`haus-warnungen.md`](./haus-warnungen.md) — Zähler-Warnungen
