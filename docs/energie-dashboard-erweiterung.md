# Energie-Dashboard — Erweiterung (Helios + Vitovalor + Beleuchtung)

Stand: 2026-06-08 · Bezug: [`energie-statistik-wartung.md`](./energie-statistik-wartung.md)

## Ausgangslage

- **Netzbezug** kommt vom **Hauptzähler** (`sensor.tasmota_mt691_total_in`).
- **Einzelgeräte** sind Shelly-/3EM-Messpunkte in `.storage/energy` → `device_consumption`.
- Steckdosen messen **alles an der Dose** (PC inkl. Router, TV-Strip inkl. Peripherie) — das ist korrekt **ein** Messpunkt, keine Lücke.
- **Mai 2026 (nach Grid-Reparatur):** Netz ~281 kWh, Geräte-Summe ~154 kWh → **~127 kWh** am Zähler ohne eigenen Messpunkt (Heizungs-/Lüftungs-Stromkreis, feste Lichtkreise an Wand-Schaltern, OG/Technik).

` sensor.helios_luftung_energy` liefert **keine Recorder-Statistik** (0 kWh) — vermutlich verwaister/alter Powercalc-Eintrag (nur in `homeassistant.exposed_entities`, nicht in Entity-Registry).

---

## Helios KWL EC 370W R

**Gerät in HA:** `Helios` / Modell `KWL EC 370W R` (easyControls, Keller Heizung).

### Literatur / Datenblatt (Richtwerte)

| Quelle | Angabe |
|--------|--------|
| Bedienungsanleitung KWL EC 270/370 Eco | 3 Förderstufen **285 / 170 / 110 m³/h**; Nennstrom Lüftung **1,0 A** (~230 W Obergrenze); Standby **&lt; 1 W** |
| Praxis / Forum (EC 370, ~280 m³/h) | **2 × 62 W** ≈ **124 W** (beide Ventilatoren) |
| Haustechnik-Praxis | Stufe 1 ~20–40 W, Stufe 2 ~40–90 W, Stufe 3 ~80–150 W (modellabhängig, mit Rohrsystem) |

**Hinweis:** Der reale Verbrauch hängt vom **Druckverlust im Kanalnetz** ab (Filter, Rohrlänge). Werte sind **Schätzung**, später am Lüftungsstromkreis kalibrierbar.

### Elektrischer Anschluss (Steckdose?)

Die **KWL EC 370W R** ist in der Regel **fest verdrahtet** (Klemmen am Gerät, eigener FI/Sicherung in der UV) — **kein** normaler Schuko-Stecker wie an einer Steckdosenleiste.

| Variante | Eignung |
|----------|---------|
| **Shelly Pro EM / 3EM** in der Unterverteilung am **Lüftungs-FI** | Empfohlen — misst den ganzen Kreis dauerhaft, Gerät läuft weiter |
| **Zwischenstecker** (Shelly Plug o. ä.) | Nur wenn am Helios **bereits eine Steckdose** sitzt (selten bei KWL) |
| **Powercalc** an `fan.helios` | **Gewählt** — keine Hardware, Schätzung aus Lüfter-% |

**Entscheidung:** Kein 3EM am Lüftungs-FI — Verbrauch über **Powercalc** (`fan.helios` → `sensor.helios_luftung_energy`).

### Steuerung in HA

`fan.helios` wird per Automation [`ventilation_auto_co2_control`](../automations.yaml) auf **percentage** gesetzt:

| CO₂ / Radon | `fan.helios` % |
|-------------|----------------|
| Default / gut | 0 |
| CO₂ &gt; 800 ppm | 10 |
| CO₂ &gt; 1100 ppm | 50 |
| Radon &gt; Schwellwert | 75 |
| Radon &gt; 110 Bq/m³ | 100 |

### Vorschlag Powercalc (YAML)

**Strategie:** `linear` + `calibrate` an `fan.helios` (Prozent 0–100), abgeleitet von EC-370-Daten (124 W ≈ 100 %).

```yaml
powercalc:
  sensors:
    - entity_id: fan.helios
      name: Helios Lüftung
      linear:
        calibrate:
          - 0 -> 3      # Standby Elektronik (~1–3 W)
          - 10 -> 35    # reduziert (~110 m³/h)
          - 50 -> 70    # mittel (~170 m³/h)
          - 75 -> 100   # erhöht
          - 100 -> 125  # max (~285 m³/h, 2×62 W)
```

**Optional später:** Zuschlag für Vor-/Nachheizung, wenn `sensor.helios_preheater_percentage` / `afterheater_percentage` &gt; 0 (separater Template-Sensor oder `states_power`).

**Energie-Dashboard:** Nach HA-Neustart `sensor.helios_luftung_energy` (oder neuer Name) unter **Einstellungen → Energie → Einzelgeräte** hinzufügen — **UI**, nicht `.storage` editieren.

**Powercalc-Neuanlage / Zähler-Reset:** Der Energie-Sensor startet bei **0 kWh**, alte Recorder-`sum` (~60 kWh) bleibt stehen → Dashboard **~-60 kWh**. Reparatur: `repair-helios-energy-statistics.sh` (auch in `repair-energie-dashboard.sh`).

**Erwartung Mai:** bei Dauerbetrieb ~50–80 W Schnitt → **~40–60 kWh/Monat** (Teil der ~127 kWh Lücke).

**Umsetzung:** `configuration.yaml` → `powercalc.sensors` (Helios Lüftung, linear/calibrate).

---

## Vitovalor PT2 (Viessmann)

**Gerät in HA:** `E3 Vitovalor PT2 0419` / Bereich Keller Heizung (`keller_heizung`), Integration **ViCare**.

Brennstoffzelle (0,75 kW<sub>el</sub>) + Spitzenlast-Gasbrenner + Pumpen/Steuerung — **kein Shelly** am Gerät, aber ViCare liefert bereits **Stromverbrauch der Anlage** (API `heating.power.consumption`).

### ViCare-Sensoren (Ist)

| Entity | Bedeutung | Stand DB (08.06.2026) |
|--------|-----------|------------------------|
| `sensor.vicare_energy_consumption_today` | Strom heute (kWh) | typ. **0,2–1,7 kWh/Tag** |
| `sensor.vicare_power_consumption_this_week` | Strom diese Woche | kWh, `total_increasing` |
| `sensor.vicare_energy_consumption_this_month` | Strom diesen Monat | **~18 kWh** (Juni, 8 Tage) |
| `sensor.vicare_energy_consumption_this_year` | Strom dieses Jahr | **~75 kWh** |

**Betriebs-Entities für Schätzung / Plausibilität:**

| Entity | Nutzen |
|--------|--------|
| `binary_sensor.vicare_burner_active` | Spitzenlastbrenner an/aus |
| `sensor.vicare_burner_modulation` | Brennerlast % |
| `binary_sensor.vicare_circulation_pump_active` | Heizkreisumwälzpumpe |
| `binary_sensor.vicare_dhw_circulation_pump_active` | WW-Zirkulationspumpe |
| `climate.vicare_heating` | Heizung ein/aus (kein reiner Brennstoffzellen-Status) |

**Nicht vorhanden:** eigener Binary „Brennstoffzelle läuft“, keine Live-Leistung in Watt über ViCare.

**Wichtig:** Der ViCare-Stromzähler misst den **Eigenstrombedarf der Vitovalor-Anlage** (Steuerung, Pumpen, Brenner-Hilfsverbrauch, BZ-Betrieb). Das ist **kein** Netto-Hausimport — passt trotzdem ins Energie-Dashboard als **Einzelgerät**, weil der Hauptzähler den **Netto**-Bezug liefert und „nicht zugeordnet“ = Differenz ist.

### Größenordnung

| Zeitraum | Schätzung |
|----------|-----------|
| Jahresschnitt 2026 (75 kWh ÷ ~5 Monate) | **~11–15 kWh/Monat** |
| Juni-Takt (18 kWh in 8 Tagen) | **~2 kWh/Tag** → evtl. **~60 kWh/Monat** (Sommer/WW; beobachten) |
| Mai 2026 (keine sauberen Tageswerte in DB) | grob **~10–15 kWh** (vom Jahresschnitt) |

→ Vitovalor erklärt **einen Teil** der ~127 kWh Lücke (nicht alles); zusammen mit Helios (~40–60 kWh) und Rest (feste Kreise, Technik) wird die Bilanz deutlich schlanker.

### Empfehlung: ViCare zuerst, Powercalc als Fallback

**Option A — ViCare direkt (bevorzugt)**

Die ViCare-Sensoren sind **echte Verbrauchswerte**, keine Watt-Schätzung. Problem: **Tages-/Monatszähler setzen sich zurück** → `statistics.sum` kann wie bei Gas/Wasser springen, wenn man den Roh-Sensor ungefiltert nutzt.

**Vorschlag für Energie-Dashboard:**

1. **Template-Sensor** `sensor.vitovalor_strom` spiegelt `sensor.vicare_energy_consumption_this_month` mit `device_class: energy` (Energie-Dashboard-Picker).
2. Fallback im Picker: **`sensor.vicare_energy_consumption_this_month`** (Friendly Name: „Vitovalor Strom Monat (ViCare)“).
3. Keine Doppelzählung mit Gas-Energie-Sensoren (`vicare_heating_gas_*` = Gas m³/kWh, anderes Medium).

**Option B — Powercalc `composite` (Schätzung)**

Nur wenn ViCare-Ausfall, fehlende Historie oder zusätzlich **Live-Watt** gewünscht. Richtwerte aus Datenblatt/Praxis: Standby/Steuerung **~80–100 W**; Brenner Spitzenlast **bis ~600 W** (modulationsabhängig); Pumpen **~35–70 W** je nach Zustand.

```yaml
powercalc:
  sensors:
    - entity_id: climate.vicare_heating
      name: Vitovalor PT2
      composite:
        mode: sum_all
        - condition:
            condition: state
            entity_id: binary_sensor.vicare_burner_active
            state: "on"
          linear:
            entity_id: sensor.vicare_burner_modulation
            calibrate:
              - 0 -> 120
              - 50 -> 350
              - 100 -> 600
        - condition:
            condition: state
            entity_id: binary_sensor.vicare_circulation_pump_active
            state: "on"
          fixed:
            power: 70
        - condition:
            condition: state
            entity_id: binary_sensor.vicare_dhw_circulation_pump_active
            state: "on"
          fixed:
            power: 35
        - fixed:
            power: 90   # Fallback: Steuerung, BZ-Hilfsverbrauch, Standby
```

**Option C — Hybrid:** Option A fürs Dashboard; Option B optional für `sensor.vitovalor_pt2_power` (Anzeige / Abgleich mit ViCare-Monatswert).

**Kalibrierung:** Monatswert ViCare vs. Powercalc-Energie vergleichen; `fixed`/`calibrate` nachziehen. Noch besser: **Shelly EM am Heizungs-FI** (Vitovalor + ggf. Pumpe — dann ggf. getrennte Kreise prüfen).

### Energie-Dashboard

**Umsetzung:** `helpers.yaml` → Template `sensor.vitovalor_strom` (Quelle `sensor.vicare_energy_consumption_this_month`, `device_class: energy`).

Nach Neustart: **Einstellungen → Energie → Einzelgeräte** → `sensor.vitovalor_strom` und `sensor.helios_luftung_energy` — **UI**, nicht `.storage` editieren.

---

## Beleuchtung (Powercalc)

**Ist:** `create_domain_groups: light` → `sensor.all_light_energy` (~2 kWh/Monat) — nur **Hue/powercalc-Schätzung** der `light.*`-Entities, **nicht** fest verkabelte Schalt-Dimmer-Kreise.

### Option A — eine Gruppe (einfach)

`all_light_energy` bleibt; im Dashboard umbenennen z. B. „Beleuchtung (geschätzt)“.

### Option B — nach Stockwerk (empfohlen)

Powercalc-Gruppen an bestehende Licht-Gruppen aus [`lights.md`](./lights.md) koppeln:

| Dashboard-Name | HA-Gruppe / Include |
|----------------|---------------------|
| Beleuchtung EG | `light.alle_lichter_erdgeschoss` |
| Beleuchtung 1. OG | `light.licht_1og_david`, `light.licht_1og_adrian` |
| Beleuchtung 2. OG | `light.licht_2og_schlafzimmer` |

YAML-Skizze (Powercalc `include` + `template`):

```yaml
powercalc:
  sensors:
    - name: Beleuchtung EG
      create_group: light_eg_energy
      include:
        template: "{{ expand('light.alle_lichter_erdgeschoss') | map(attribute='entity_id') | list | join(',') }}"
    # analog 1OG / 2OG
```

**Achtung:** Nicht zusätzlich `kuche_energy` / Raum-powercalc — würde mit Einzelleuchtern doppelt zählen.

### Option C — Kategorien

- **Hauptlicht** (Drehregler Ess/Wohn: `hauptlicht_*`)
- **Deko/LED** (TV/Couch-LED, Iris, Regal)
- **OG Kinderzimmer**

Nur sinnvoll, wenn im Dashboard getrennte Balken gewünscht — sonst reicht Option B.

---

## Abgleich / keine Doppelzählung

| Prüfen | Aktion |
|--------|--------|
| HA-Server an TV-Strip **und** eigene Shelly `homeassistant`? | Nur **einen** Eintrag im Dashboard |
| `alle_lichter_*` + Einzelleuchten in Powercalc | Nur Gruppen **oder** Domain-Group, nicht beides |
| Helios Shelly **und** Powercalc | Nur **eine** Quelle im Dashboard |
| Vitovalor ViCare **und** Powercalc | Nur **eine** Quelle (ViCare bevorzugt) |
| Vitovalor-Strom + Gas-Sensoren ViCare | Strom ≠ Gas — beides ok, verschiedene Medien |
| Heizungs-FI misst Vitovalor + Helios gemeinsam | Dann **ein** EM-Messpunkt oder Aufteilung über ViCare/Powercalc |

---

## Umsetzung

| Schritt | Status |
|---------|--------|
| Helios Powercalc in `configuration.yaml` | ✅ |
| Vitovalor Template `sensor.vitovalor_strom` in `helpers.yaml` | ✅ |
| Energie-Dashboard UI (Einzelgeräte) | **Nutzer** — siehe unten |
| Licht-Gruppen (Option B/C) | offen |

**Dein Test nach Neustart / YAML-Reload:**

1. Entwicklerwerkzeuge → `sensor.helios_luftung_power` / `_energy` und `sensor.vitovalor_strom` prüfen.
2. Einstellungen → Energie → Einzelgeräte: `sensor.helios_luftung_energy`, `sensor.vitovalor_strom` hinzufügen.
3. Plausibilität: Vitovalor-Monat ≈ `sensor.vicare_energy_consumption_this_month`.

---

## Offen

- [x] Helios: Powercalc (kein 3EM)
- [x] Vitovalor: ViCare via Template → `sensor.vitovalor_strom`
- [ ] Energie-Dashboard UI: beide Sensoren unter Einzelgeräte
- [ ] Welche Licht-Option (A/B/C) im Dashboard?
