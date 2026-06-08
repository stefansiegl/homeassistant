# Energie-Dashboard — Statistik-Wartung

Recorder-**Statistik** (`statistics` / `statistics_short_term`) kann durch Geräte-Ausreißer verfälscht sein, während Live-Entities plausibel bleiben. Symptome: unrealistische **Tages-/Monatswerte** oder **Kosten** im Energie-Dashboard.

## Quellen im Dashboard

| Medium | Entity (Verbrauch) | Kosten-Entity | Preis |
|--------|-------------------|---------------|-------|
| Strom Bezug | `sensor.tasmota_mt691_total_in` | `sensor.tasmota_mt691_total_in_cost` | 0,33376 €/kWh (`.storage/energy`) |
| Strom Einspeisung | `sensor.tasmota_mt691_total_out` | `sensor.tasmota_mt691_total_out_compensation` | 0,23 €/kWh |
| Gas | `sensor.gasmeter_value_stabil` | — (Preis in UI) | `input_number.gaspreis_pro_m3` (1,32) |
| Wasser | `sensor.watermeter_value_stabil` | — (Preis in UI) | 3,52 €/m³ |

Kosten im Dashboard = **Verbrauchs-Deltas × Preis** (`.storage/energy`: `stat_cost: null`). Die HA-Kosten-Sensoren (`*_cost`) sind **aus dem Recorder ausgeschlossen** — HA schreibt deren `sum` falsch zurück und erzeugt Minus-Tageswerte.

Verbrauch = **Deltas** der `sum`-Spalte der Verbrauchs-Entity.

## Standard-Workflow (immer zusammen)

Nach **Entity-Umstellung**, **Seed**, **Core-Neustart** oder **komischen Kosten/Verbräuchen** (ein oder mehrere Medien):

```bash
# optional: nur prüfen
DB_PASS='…' /config/bin/check-energie-statistik.sh

# Reparatur Strom + Gas + Wasser in einem Lauf
DB_PASS='…' /config/bin/repair-energie-dashboard.sh
```

Danach Energie-Dashboard **Strg+F5**. Einzel-Skripte nur bei gezieltem Debugging.

Das Master-Skript **entfernt** am Ende Kosten-Statistik (`purge-energie-cost-statistics.sh`) — Kosten kommen nur noch aus Verbrauch × Preis.

**Automatik:** Automationen `Energie: Statistik-Wartung` (20 Min nach Neustart + täglich 04:00) via `shell_command.repair_energie_dashboard`.

**Warum zusammen?** HA kann bei Neustart/Seed die `sum`-Spalte neu kompilieren (`Compiling initial sum statistics`) — das betrifft oft mehrere Quellen gleichzeitig; nur Wasser zu fixen lässt Strom/Gas weiter falsch.

| Schritt | Skript |
|---------|--------|
| Diagnose | `check-energie-statistik.sh` |
| Alles reparieren | `repair-energie-dashboard.sh` |
| Nur Strom | `repair-grid-statistics.sh` |
| Nur Gas | `repair-gasmeter-statistics.sh` |
| Nur Wasser | `repair-watermeter-statistics.sh` (`META_ID_VALUE=1266`, `META_ID_COST=1268`) |
| Nur Kosten | `sync-gasmeter-cost.sh` |

## Strom (Tasmota MT691)

**Symptom:** Stromkosten in **100.000en** (z. B. Mai/Juni 2026), obwohl Zählerstand (`state`) ~17.000 kWh plausibel.

**Ursache:** `sum` in der Statistik springt durch fehlerhafte `state`-Werte (z. B. **1000** statt ~17.000) und akkumuliert falsche kWh.

**Reparatur:** bevorzugt `repair-energie-dashboard.sh` (siehe oben); nur Strom: `repair-grid-statistics.sh`.

- Sprung-Filter: max. **+35 kWh/h**, Artefakt **`state` &lt; 5000** bei Zähler &gt; 5000 wird verworfen
- setzt `sum` neu; synchronisiert Kosten-/Vergütungs-Statistik via `sync-gasmeter-cost.sh`

**Nach dem Lauf:** Energie-Dashboard **Strg+F5**.

## Gas / Wasser (AI-on-the-Edge)

Siehe [`ai-on-the-edge.md`](./ai-on-the-edge.md) — Abschnitte Statistik-Reparatur, DB-Restore, `sync-gasmeter-cost.sh`.

**Wasser — Prävention:** `sensor.watermeter_value_stabil` (Trigger-Template) filtert OCR-Ausreißer vor der Recorder-Statistik; Roh-Entity `sensor.watermeter_value` ist aus dem Recorder ausgeschlossen. Energie-Dashboard-Quelle in der UI auf **stabil** stellen. Reparatur-Skript nur noch für **historische** Daten nötig.

## Nur Kosten (ohne Werte-Reparatur)

```bash
DB_PASS='…' /config/bin/sync-gasmeter-cost.sh
```

Parameter: `GAS_PRICE`, `META_ID_VALUE`, `META_ID_COST` (Strom Import: `475`/`466`, Preis `0.33376`).

## Geräte vs. Netzbezug („fehlender“ Strom)

Das Energie-Dashboard zeigt unter **Einzelgeräten** nur die in `.storage/energy` → `device_consumption` eingetragenen Sensoren. Der **Netzbezug** (`sensor.tasmota_mt691_total_in`) misst **alles** am Hauszähler; die Differenz erscheint als **nicht zugeordnet** — das ist kein Recorder-Fehler.

**Typische Abweichung (Beispiel Mai 2026, nach Reparatur):**

| | kWh |
|--|-----|
| Netzbezug | ~281 |
| Summe 17 Geräte (Shelly/powercalc) | ~154 (~55 %) |
| Nicht zugeordnet | ~127 (~45 %) |

**Warum die Lücke groß wirkt:**

1. **Historie:** Viele Küchen-/Herd-Sensoren erst ab **02/2026** im Dashboard — ältere Monate zeigen nur ~20 % zugeordnet.
2. **Nicht im Dashboard, aber in HA vorhanden:** z. B. `sensor.helios_luftung_energy` (Lüftung), `sensor.all_standby_energy`, Powercalc-Räume (`kuche_energy`, `badezimmer_energy`).
3. **Am Zähler, ohne Submessung:** Heizungs-/Hausverteiler-Strom (Viessmann Vitovalor, Pumpen, Steuerung), fest verdrahtete Licht-/Steckdosenkreise OG/EG, Netzwerk, Router, Relais — alles läuft über den MT691, nur Steckdosen mit Shelly sind einzeln sichtbar.
4. **PV:** Solar (`sensor.fritz_dect_210_1_energie`) reduziert Netzbezug; Einspeisung ist separat — ersetzt keine Geräte-Zuordnung.

**Sinnvolle Erweiterungen (UI):** Einstellungen → Energie → Einzelgeräte: Helios Lüftung, ggf. weitere Shelly/3EM-Kreise. Keine Doppelzählung (z. B. nicht zusätzlich `kuche_energy`, wenn Küchen-Steckdosen schon einzeln drin sind).

## Wichtig

- Reparatur **einmal** auf sauberer DB; bei Verschlimmerung zuerst **MariaDB-Restore** (Gas/Wasser: `ai-on-the-edge.md`)
- Cursor-Regel: `.cursor/rules/aiot-statistik-wartung.mdc` (Strom/Gas/Wasser)
