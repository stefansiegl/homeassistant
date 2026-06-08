# Energie-Dashboard — Statistik-Wartung

Recorder-**Statistik** (`statistics` / `statistics_short_term`) kann durch Geräte-Ausreißer verfälscht sein, während Live-Entities plausibel bleiben. Symptome: unrealistische **Tages-/Monatswerte** oder **Kosten** im Energie-Dashboard.

## Quellen im Dashboard

| Medium | Entity (Verbrauch) | Kosten-Entity | Preis |
|--------|-------------------|---------------|-------|
| Strom Bezug | `sensor.tasmota_mt691_total_in` | `sensor.tasmota_mt691_total_in_cost` | 0,33376 €/kWh (`.storage/energy`) |
| Strom Einspeisung | `sensor.tasmota_mt691_total_out` | `sensor.tasmota_mt691_total_out_compensation` | 0,23 €/kWh |
| Gas | `sensor.gasmeter_value` | `sensor.gasmeter_value_cost` | `input_number.gaspreis_pro_m3` (1,32) |
| Wasser | `sensor.watermeter_value` | `sensor.watermeter_value_cost` | 3,52 €/m³ |

Kosten = **`val.sum` × Preis**; Perioden = **Deltas** der `sum`-Spalte.

## Strom (Tasmota MT691)

**Symptom:** Stromkosten in **100.000en** (z. B. Mai/Juni 2026), obwohl Zählerstand (`state`) ~17.000 kWh plausibel.

**Ursache:** `sum` in der Statistik springt durch fehlerhafte `state`-Werte (z. B. **1000** statt ~17.000) und akkumuliert falsche kWh.

**Reparatur:**

```bash
DB_PASS='…' /config/bin/repair-grid-statistics.sh
```

- Sprung-Filter: max. **+35 kWh/h**, Artefakt **`state` &lt; 5000** bei Zähler &gt; 5000 wird verworfen
- setzt `sum` neu; synchronisiert Kosten-/Vergütungs-Statistik via `sync-gasmeter-cost.sh`

**Nach dem Lauf:** Energie-Dashboard **Strg+F5**.

## Gas / Wasser (AI-on-the-Edge)

Siehe [`ai-on-the-edge.md`](./ai-on-the-edge.md) — Abschnitte Statistik-Reparatur, DB-Restore, `sync-gasmeter-cost.sh`.

## Nur Kosten (ohne Werte-Reparatur)

```bash
DB_PASS='…' /config/bin/sync-gasmeter-cost.sh
```

Parameter: `GAS_PRICE`, `META_ID_VALUE`, `META_ID_COST` (Strom Import: `475`/`466`, Preis `0.33376`).

## Wichtig

- Reparatur **einmal** auf sauberer DB; bei Verschlimmerung zuerst **MariaDB-Restore** (Gas/Wasser: `ai-on-the-edge.md`)
- Cursor-Regel: `.cursor/rules/aiot-statistik-wartung.mdc` (Gas/Wasser; Strom analog)
