# Energie-Statistik — Prävention statt Reparatur-Schleife

Zielarchitektur für das native Home-Assistant-Energie-Dashboard. Ersetzt die nächtliche DB-Reparatur durch **Live-Filter (Stabil-Templates)** und **einmalige Migration**.

Siehe auch: [`energie-statistik-wartung.md`](./energie-statistik-wartung.md) (Notfall-Reparatur), [`ai-on-the-edge.md`](./ai-on-the-edge.md) (Gas/Wasser OCR).

## Prinzip

| Schicht | Aufgabe |
|---------|---------|
| **Stabil-Template** | Ausreißer filtern, bevor sie in den Recorder gelangen |
| **recorder.exclude (Roh)** | Keine korrupte Roh-Historie; Neustart kompiliert `sum` nicht aus Spikes |
| **Energie-Dashboard** | Nur `*_stabil`-Entities + `input_number`-Preis-Helfer |
| **Kosten** | Template `sensor.*_stabil_kosten` (= Verbrauch stabil × `input_number`-Preis), Recorder — **kein** Sync-Skript |
| **Monitoring** | `check-energie-statistik-anomaly.sh` 2×/Tag → `notify.haus_warnungen` (kein Auto-Repair) |

**Nicht mehr:** tägliche Automation `repair_energie_dashboard` (04:00 / nach Neustart).

## Entities

### Verbrauch

| Medium | Roh (exclude) | Dashboard / Recorder |
|--------|---------------|----------------------|
| Strom Bezug | `sensor.tasmota_mt691_total_in` | `sensor.mt691_total_in_stabil` |
| Strom Einspeisung | `sensor.tasmota_mt691_total_out` | `sensor.mt691_total_out_stabil` |
| Strom Leistung (Stromquellen) | `sensor.tasmota_mt691_power_cur` | `sensor.mt691_power_cur_stabil` |
| Gas | `sensor.gasmeter_value` | `sensor.gasmeter_value_stabil` |
| Wasser | `sensor.watermeter_value` | `sensor.watermeter_value_stabil` |

Stabil-Sensoren haben Attribute `raw_value`, `filtered`, `last_accepted_ts`.

### Preise (`input_number` in `helpers.yaml`)

| Entity | Einheit | Energie-UI-Feld |
|--------|---------|-----------------|
| `input_number.gaspreis_pro_m3` | EUR/m³ | Gas → Preis-Entity |
| `input_number.wasserpreis_pro_m3` | EUR/m³ | Wasser → Preis-Entity |
| `input_number.strompreis_pro_kwh` | EUR/kWh | Netz → Preis-Entity |
| `input_number.einspeiseverguetung_pro_kwh` | EUR/kWh | Netz → Einspeisungsvergütung |

`min: 0.01`, `step: 0.01` — kein versehentliches 0.

## Einmalige Migration (Alt → Neu)

**Reihenfolge:**

1. YAML deployen + `ha core check` + **Core-Neustart** (Stabil-Entities + Preis-Helfer)
2. `DB_PASS='…' /config/bin/migrate-energie-statistik.sh`
3. **Nutzer in HA-UI** (Einstellungen → Energie):
   - Netz Bezug: `sensor.mt691_total_in_stabil`
   - Netz Einspeisung: `sensor.mt691_total_out_stabil`
   - Gas/Wasser Preis: `input_number.gaspreis_pro_m3` / `input_number.wasserpreis_pro_m3` (falls noch feste Zahl)
   - Netz Preis: `input_number.strompreis_pro_kwh` / `input_number.einspeiseverguetung_pro_kwh`
   - Netz Leistung (Stromquellen): `sensor.mt691_power_cur_stabil` statt `sensor.tasmota_mt691_power_cur`
   - Backfill Leistung-Historie: `seed-mt691-power-stabil-statistics.sh` (einmalig)
4. `DB_PASS='…' /config/bin/repair-mt691-stabil-statistics.sh` (Pflicht nach UI-Umstellung — behebt fehlende Tage durch `sum`-Sprung auf ~0)
5. Energie-Dashboard **Strg+F5**; Mai/Juni Stichprobe (Kosten über Recorder)

**Skript-Ablauf intern (Migration):** Roh-Strom reparieren → Seed Strom stabil → Wasser/Gas stabil reparieren (falls nötig). Kosten-Sync nur bei Lücken/Notfall.

`seed-gasmeter-stabil-statistics.sh` nur **einmal** in der Migration — nie im Cron.

## Notfall (nur bei Anomalie)

```bash
DB_PASS='…' /config/bin/check-energie-statistik.sh
DB_PASS='…' /config/bin/repair-energie-dashboard.sh   # manuell, nicht automatisch
```

Danach Strg+F5. Nicht auf bereits migrierte Daten wiederholt laufen lassen.

## Monitoring

- **08:00 / 20:00:** `shell_command.check_energie_statistik_anomaly` → bei Befund `notify.haus_warnungen`
- **Stabil `filtered: true`:** optional Automation auf `sensor.*_stabil` (OCR/Tasmota abgefangen)

## Kosten-Recorder (seit 2026-06-11)

**Template-Kosten** (YAML, `configuration.yaml`) — Recorder schreibt stündlich in MariaDB:

| Medium | Entity | Formel |
|--------|--------|--------|
| Gas | `sensor.gasmeter_stabil_kosten` | `gasmeter_value_stabil` × `gaspreis_pro_m3` |
| Wasser | `sensor.watermeter_stabil_kosten` | `watermeter_value_stabil` × `wasserpreis_pro_m3` |
| Strom Bezug | `sensor.strom_bezug_stabil_kosten` | `mt691_total_in_stabil` × `strompreis_pro_kwh` |
| Einspeisung | `sensor.strom_einspeisung_stabil_verguetung` | `mt691_total_out_stabil` × `einspeiseverguetung_pro_kwh` |

Energie-Dashboard (`.storage/energy`): `stat_cost` / `stat_compensation` zeigen auf diese Entities.

**Nicht aufzeichnen:** HA-Auto-Kosten der Energy-Integration (`sensor.gasmeter_value_stabil_cost_2`, …) — andere Semantik, erzeugte Fehlalarme.

**Notfall** (Minus-Tageskosten): betroffene Template-Entity prüfen; einmalig `repair-energie-dashboard.sh` — **kein** Dauer-Sync.

## Preisänderung

Template rechnet live mit aktuellem `input_number`-Preis → Recorder-Statistik ab der Änderung mit neuem Preis. Keine Automation, kein Sync.
