# Energie-Dashboard — Erweiterung (Helios + Vitovalor + Beleuchtung)

Stand: 2026-06-09 · Bezug: [`energie-statistik-wartung.md`](./energie-statistik-wartung.md) · Haushalt Hebeanlage: [`haushalt-hebeanlage.md`](./haushalt-hebeanlage.md)

## Ausgangslage

- **Netzbezug** kommt vom **Hauptzähler** (`sensor.tasmota_mt691_total_in`).
- **Einzelgeräte** sind Shelly-/3EM-Messpunkte in `.storage/energy` → `device_consumption`.
- Steckdosen messen **alles an der Dose** (PC inkl. Router, TV-Strip inkl. Peripherie) — das ist korrekt **ein** Messpunkt, keine Lücke.
- **Mai 2026 (nach Grid-Reparatur):** Netz ~281 kWh, Geräte-Summe ~154 kWh → **~127 kWh** am Zähler ohne eigenen Messpunkt (Heizungs-/Lüftungs-Stromkreis, feste Lichtkreise an Wand-Schaltern, OG/Technik).

` sensor.helios_luftung_energy` liefert **keine Recorder-Statistik** (0 kWh) — vermutlich verwaister/alter Powercalc-Eintrag (nur in `homeassistant.exposed_entities`, nicht in Entity-Registry).

---

## FI-Matrix UV „Am Oberfeld 48“ (Messstand)

| SK / Kreis | Verbraucher | Messung | Entity / Quelle | Status |
|------------|-------------|---------|-----------------|--------|
| **Zählerkette** | Netzbezug VNB | ISKRA MT691 + Tasmota IR | `sensor.mt691_total_in_stabil` | ✅ |
| **Küche 3PH** | Herd, Spülmaschine, Kochfeld | Shelly Pro 3EM | `sensor.*_shellypro3em_*` | ✅ |
| **SK 16** | Helios KWL EC 370W R (fest verdrahtet) | Powercalc | `sensor.helios_luftung_energy` | ✅ geschätzt |
| **SK 16** | (optional) | **Shelly Pro EM-50** am Lüftungs-FI | — | 📋 Phase 3b nach Bilanz |
| **SK 18** | FBH-Pumpen (fest verdrahtet) | — | — | ❌ ungemessen |
| **SK 20/21** | Vitovalor + Nebenverbrauch | ViCare API | `sensor.vicare_energy_consumption_this_month` | ✅ (nur Anlage) |
| **SK 20/21** | Hebeanlage (Schuko) | Nous A1Z | `sensor.steckdose_keller_hebeanlage_energy` | ✅ seit 09.06.2026 |
| **SK 20/21** | Grünbeck Enthärtung (Schuko) | Nous A1Z (2. Steckdose) | steckdose_keller_gruenbeck_energy (nach Pairing) | ⏳ Nutzer |
| **Steckdosen** | Küche, Multimedia, Technikraum, Haushalt | Nous A1Z / Shelly Plug | siehe `.storage/energy` | ✅ |
| **Licht** | Hue + Powercalc | Domain-Group | `sensor.all_light_energy` | ✅ geschätzt |
| **Garage** | leer | — | — | — |

**Regel:** Steckdose misst nur **diese Dose**; FI-Kreise (Lüftung, FBH) brauchen **Shelly Pro EM-50** (Hutschiene) — siehe Hardware-Abschnitt unten.

---

## Hardware-Einkauf (Nous / Shelly)

| Produkt | Modell | Einsatz | Beschaffung (ca. Juni 2026) |
|---------|--------|---------|----------------------------|
| **Nous A1Z** | Zigbee 16 A, Messung | Schuko (Hebeanlage, Grünbeck, Küche) | BerryBase 2er ~29 € |
| **Shelly Plus Plug S** | SNPL-00112EU, 12 A | WiFi-Steckdosen (Alternative) | reichelt ~21 € |
| **Shelly Pro EM-50** | SPEM-002CEBEU50 | SK 16 Lüftung, optional SK 18 FBH | Amazon ~67 € |
| **Shelly Pro 3EM** | SPEM-003CEBEU | nur 3 Phasen (Küche, bereits) | — |

Nachkauf Zigbee: gleicher Chip `a4c138` / [Z2M A1Z](https://www.zigbee2mqtt.io/devices/A1Z.html). Z2M-Friendly-Name für Grünbeck: **`Steckdose-Keller-Gruenbeck`** → HA-Entities `sensor.steckdose_keller_gruenbeck_*`.

---

## Juni-Bilanz 2026 (Phase 1, Stand 09.06.)

| Kennzahl | Wert |
|----------|------|
| Netzbezug Juni (MT691 stabil) | **50,75 kWh** (Monatsanfang bis 09.06.) |
| Summe Einzelgeräte (Dashboard-Liste) | **~29,5 kWh** |
| **Nicht zugeordnet (geschätzt)** | **~21 kWh** (~41 % des Netzbezugs) |

Größte ungemessene Verdächtige (weiterhin): **Lüftung SK 16** (nur Powercalc), **FBH SK 18**, feste Licht-/Technik-Kreise.

**Entscheidung Phase 3b:** Nach vollständigem Juni-Monat Bilanz wiederholen (`DB_PASS=… /config/bin/check-energie-statistik.sh` + Geräte-Summe aus DB). Bei anhaltender Lücke **>15–20 %**: **Shelly Pro EM-50** am **SK 16** (Elektriker oder DIY spannungsfrei, siehe Montage in Einkaufsplan). Dann **Helios Powercalc aus Dashboard entfernen** (keine Doppelzählung).

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

**Energie-Dashboard:**

1. **`sensor.vicare_energy_consumption_this_month`** direkt (Friendly Name: „Vitovalor Strom“) — ViCare-Integration, `device_class: energy`, funktionierende `statistics.sum`.
2. **Kein** Template-Spiegel (`sensor.vitovalor_strom` entfernt): gleicher Live-Wert, aber `sum`-Statistik im Dashboard wertlos.
3. **Monats-Reset:** Wert fällt am Monatsanfang auf 0 — mit `state_class: total_increasing` normales HA-Verhalten; Historie des Vormonats bleibt in der Statistik (nach Monatswechsel kurz prüfen).
4. **`_today` nicht** fürs Dashboard — nur Tageswert, mehr Reset-Punkte; `_this_month` passt zur Monatsansicht.
5. Keine Doppelzählung mit Gas-Energie-Sensoren (`vicare_heating_gas_*` = Gas m³/kWh, anderes Medium).

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

**Option C — Hybrid:** Option A fürs Dashboard; Option B optional für Powercalc-Sensor vitovalor_pt2_power (Anzeige / Abgleich mit ViCare-Monatswert).

**Kalibrierung:** Monatswert ViCare vs. Powercalc-Energie vergleichen; `fixed`/`calibrate` nachziehen. Noch besser: **Shelly EM am Heizungs-FI** (Vitovalor + ggf. Pumpe — dann ggf. getrennte Kreise prüfen).

### Energie-Dashboard

**Umsetzung:** `sensor.vicare_energy_consumption_this_month` unter **Einstellungen → Energie → Einzelgeräte** (Friendly Name über `configuration.yaml` → „Vitovalor Strom“). Zusätzlich: `sensor.helios_luftung_energy` — **UI**, nicht `.storage` editieren.

Falls noch `sensor.vitovalor_strom` eingetragen: in der UI **entfernen** und durch `sensor.vicare_energy_consumption_this_month` ersetzen.

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
| Hebeanlage Steckdose + Vitovalor ViCare | Kein Doppel — unterschiedliche Lasten (Pumpe vs. Anlage) |

---

## Shelly Pro EM-50 — Montage SK 16 (Kurzreferenz)

1. **UV-Zuleitung aus**, FI SK 16 aus, spannungsfrei prüfen (zweipolig).
2. Pro EM auf Hutschiene; **L und N** des Lüftungskreises **nach FI** durch EM (Durchgang).
3. Shelly-Versorgung L+N vom Busbar (eigener B10A-LS).
4. WLAN in UV testen; HA Shelly-Integration → `sensor.*_energy` ins Dashboard.
5. **Helios Powercalc** aus `device_consumption` entfernen.

Details + Sicherheit: Einkaufsplan Strom-Hardware (Montage-Abschnitt).

---

## Grünbeck — zweite Nous A1Z (ausstehend)

1. Steckdose zwischen Wanddose und Grünbeck-Stecker (wie Hebeanlage).
2. Z2M pairen → Friendly Name **`Steckdose-Keller-Gruenbeck`**.
3. `power_outage_memory` → **on**.
4. Energie-Dashboard: steckdose_keller_gruenbeck_energy + _power hinzufügen (UI oder `.storage/energy`).

---

## Umsetzung

| Schritt | Status |
|---------|--------|
| Helios Powercalc in `configuration.yaml` | ✅ |
| Vitovalor: `sensor.vicare_energy_consumption_this_month` im Dashboard | ✅ (`.storage/energy`, 09.06.) |
| Hebeanlage: Nous A1Z + Energie-Dashboard | ✅ |
| Grünbeck: Nous A1Z #2 | ⏳ Nutzer (Pairing + Dashboard) |
| Phase 3b: Shelly Pro EM-50 SK 16 | 📋 nach Juni-Vollbilanz |
| Licht-Gruppen (Option B/C) | offen |

**Dein Test:**

1. Entwicklerwerkzeuge → `sensor.steckdose_keller_hebeanlage_power` / `_energy` (Hebeanlage).
2. Energie-Dashboard: Hebeanlage, Vitovalor (`_this_month`), Helios sichtbar; „nicht zugeordnet“ beobachten.
3. Nach Grünbeck-Pairing: steckdose_keller_gruenbeck_energy ergänzen.

---

## Offen

- [x] Helios: Powercalc (kein 3EM vorerst)
- [x] Vitovalor: ViCare `_this_month` im Dashboard (nicht `_today`)
- [x] Hebeanlage: `sensor.steckdose_keller_hebeanlage_energy` im Dashboard
- [ ] Grünbeck: zweite Nous A1Z pairen + Dashboard
- [ ] Juni-Vollbilanz Ende Juni → Entscheid Pro EM SK 16
- [ ] Welche Licht-Option (A/B/C) im Dashboard?
