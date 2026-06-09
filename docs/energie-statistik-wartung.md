# Energie-Dashboard — Statistik-Wartung

**Architektur (Prävention):** [`energie-statistik-praevention.md`](./energie-statistik-praevention.md) — Stabil-Templates, keine nächtliche Auto-Reparatur.

Recorder-**Statistik** kann durch Geräte-Ausreißer verfälscht sein. Symptome: unrealistische **Tages-/Monatswerte** oder **Kosten** im Energie-Dashboard.

## Quellen im Dashboard

| Medium | Entity (Verbrauch) | Preis (UI) |
|--------|-------------------|------------|
| Strom Bezug | `sensor.mt691_total_in_stabil` | `input_number.strompreis_pro_kwh` |
| Strom Einspeisung | `sensor.mt691_total_out_stabil` | `input_number.einspeiseverguetung_pro_kwh` |
| Gas | `sensor.gasmeter_value_stabil` | `input_number.gaspreis_pro_m3` |
| Wasser | `sensor.watermeter_value_stabil` | `input_number.wasserpreis_pro_m3` |

In `.storage/energy`: `stat_cost` / `stat_compensation` = **`null`** — HA legt `sensor.*_cost` an; das Frontend liest Kosten aus deren **Recorder-Statistik** (`energy/info` → `cost_sensors`).

Verbrauch = **Deltas** der `sum`-Spalte der Verbrauchs-Entity.  
Kosten = **Deltas** der `sum`-Spalte der `*_cost`-Statistik (gefüllt per `sync-energie-cost-all.sh` aus Verbrauch × Preis-Helfer).

## Kosten-Sensoren & Recorder

`**_cost` / `*_compensation`** in `recorder.exclude` — keine fehlerhaften Live-States. Kosten-Statistik per **`sync-energie-cost-all.sh`** (liest Preise aus `input_number.*`).

**Nicht tun:** `purge-energie-cost-statistics.sh` ohne anschließenden Sync — Dashboard zeigt **0 € trotz Verbrauch**.

### „Entität nicht nachverfolgt“ bei `*_cost`

Gewollt — Verbrauchs-Entities (`*_stabil`) werden normal aufgezeichnet.

## Workflow

| Situation | Aktion |
|-----------|--------|
| **Einmalige Umstellung** | `migrate-energie-statistik.sh` + Energie-UI + Strg+F5 |
| **Preis geändert** | Automation synchronisiert Kosten; oder `sync-energie-cost-all.sh` |
| **Anomalie (Monitoring)** | `notify.haus_warnungen` — manuell `repair-energie-dashboard.sh` |
| **Diagnose** | `check-energie-statistik.sh` / `check-energie-statistik-anomaly.sh` |

**Keine Automation** repariert nachts mehr automatisch (`energie_statistik_wartung_*` entfernt).

```bash
DB_PASS='…' /config/bin/check-energie-statistik.sh
DB_PASS='…' /config/bin/migrate-energie-statistik.sh      # einmalig
DB_PASS='…' /config/bin/repair-energie-dashboard.sh       # Notfall, manuell
DB_PASS='…' /config/bin/sync-energie-cost-all.sh
```

## Strom (MT691)

**Prävention:** `sensor.mt691_total_in_stabil` / `_out_stabil` filtern Tasmota-Spikes; Roh-Entities `recorder.exclude`.

**Notfall-Reparatur Roh-Historie:** `repair-grid-statistics.sh` → `seed-mt691-stabil-statistics.sh` (einmalig).

## Gas / Wasser (AI-on-the-Edge)

Siehe [`ai-on-the-edge.md`](./ai-on-the-edge.md). Stabil-Templates + Roh exclude. `seed-gasmeter-stabil-statistics.sh` nur **einmal** bei Migration.

## Geräte vs. Netzbezug

Netzbezug misst alles am Hauszähler; Differenz zu Einzelgeräten = **nicht zugeordnet** (kein Recorder-Fehler). Siehe [`energie-dashboard-erweiterung.md`](./energie-dashboard-erweiterung.md).
