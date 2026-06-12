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

Verbrauch = **Deltas** der `sum`-Spalte der Verbrauchs-Entity (`*_stabil`).  
Kosten = **Deltas** der `sum`-Spalte der Template-Kosten-Entities (`sensor.gasmeter_stabil_kosten`, …).

## Kosten-Sensoren & Recorder

**Inkrementelle Template-Kosten** — ΔVerbrauch × `input_number`-Preis; siehe [`energie-statistik-praevention.md`](./energie-statistik-praevention.md).

HA-Auto-`_*_cost` bleiben in `recorder.exclude` (doppelte/instabile Quelle).

**Normalbetrieb:** kein Sync, keine Automation. Recorder + Templates reichen.

**Notfall** (Minus-Tageskosten, Lücken): `repair-energie-dashboard.sh` oder `sync-energie-cost-all.sh` — danach Strg+F5. **Nicht** `purge-energie-cost-statistics.sh` ohne Nachpflege.

## Workflow

| Situation | Aktion |
|-----------|--------|
| **Einmalige Umstellung** | `migrate-energie-statistik.sh` + Energie-UI + Strg+F5 |
| **Preis geändert** | Neue Stunden mit neuem Preis automatisch; Historie nur bei Bedarf `sync-energie-cost-all.sh` |
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
