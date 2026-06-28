# Klima & Lüftung (Helios KWL EC 370W R)

Zentrale Steuerung der Helios-Wohnraumlüftung über Home Assistant: CO₂, optionale Nacht-Kühlung, Radon (optional), Not-Aus.

## Ziel

- **Gesunde Luft:** CO₂ im Schlafzimmer nachts nicht dauerhaft >1500 ppm
- **Sommer-Nacht-Kühlung:** Kühle Außenluft nutzen, wenn Bypass aktiv und drinnen wärmer — nur bei gutem CO₂
- **Nachvollziehbar:** `sensor.luftung_status` zeigt *warum* die Anlage läuft
- **Sicher:** `input_boolean.ventilation_kill_switch` (Not-Aus) stoppt die Lüftung **sofort** und erzwingt 0 %

## Entities

### Steuerung & Status

| Entity | Typ | Rolle |
|--------|-----|-------|
| `fan.helios` | fan | Helios-Lüfter (% Stufe) |
| `sensor.luftung_status` | sensor | Klartext-Grund + Attribute (`ziel_prozent`, `grund_code`, …) |
| `sensor.luftung_ziel_prozent` | sensor | Soll-% für Recorder/Graphen (spiegelt `ziel_prozent`) |
| `sensor.luftung_grund_stufe` | sensor | Numerischer Steuergrund für Graphen (Legende im Attribut `legende`) |
| `input_boolean.ventilation_kill_switch` | input_boolean | Not-Aus (UI: Dashboard Lüftungszentrale) |
| `input_boolean.radon_logic_enabled` | input_boolean | Radon-Boost ein/aus |

### CO₂ & Klima

| Entity | Raum |
|--------|------|
| `sensor.house_max_co2` | Max aller Aranet-Sensoren |
| `sensor.db_04_e6_6d_44_0d_carbon_dioxide` | Schlafzimmer (2. OG) — **gewichtet** |
| `sensor.aranet4_02_kueche_carbon_dioxide` | Küche |
| `sensor.aranet4_01_arbeitszimmer_carbon_dioxide` | Büro |
| `sensor.c9_46_fc_e8_90_d9_carbon_dioxide` | 1. OG |
| `binary_sensor.helios_bypass` | Sommer-Bypass (on = Sommer) |
| `sensor.helios_outside_air_temperature` | Außenluft (Helios) |
| `sensor.db_04_e6_6d_44_0d_temperature` | Schlafzimmer-Temp |

### Effektives CO₂

`co2_effektiv = max(house_max_co2, schlafzimmer_co2)` aus verfügbaren Werten.

## Zeitprofile

| Profil | Uhrzeit | Beschreibung |
|--------|---------|--------------|
| `tag` | 07:00–22:00 | Aggressiv (du bist wach) |
| `abend` | 22:00–02:00 | CO₂ + Kühlung, max. 50 % |
| `nacht` | 02:00–05:00 | CO₂ + Kühlung bei Bedarf, max. 50 % |
| `morgen` | 05:00–07:00 | CO₂-Abbau nach der Nacht, max. 50 % |

## Lüfter-Ziel (%) — Logik

**Priorität:** Not-Aus → Radon (wenn aktiv) → CO₂ → Nacht-Kühlung → Aus

### CO₂ (profilabhängig)

| co2_effektiv | tag | abend / nacht | morgen |
|--------------|-----|---------------|--------|
| ≤ 750 | 0 | 0 | 0 |
| > 750 | 15 | — | 15 |
| > 950 | 30 | 15 | — |
| > 1150 | 50 | **50** | **50** |
| > 1400 | 75 | **50** | **50** |
| > 1800 | 100 | 50 | **50** |

### Sommer-Hitze-Sperre (Bypass = Sommer)

Wenn `binary_sensor.helios_bypass` = on **und** Schlafzimmer nicht mindestens 1 °C wärmer als Außenluft:

- CO₂-Lüftung **unter 50 %** wird **unterdrückt** (`grund_code: co2_hitze_sperre`)
- Ab **> 995 ppm** (`co2_effektiv`) läuft Lüftung weiter — unterhalb der „grün“-Schwelle der Sensoren (< 1000 ppm)
- Nacht-Kühlung bleibt unverändert (eigene ΔT-Regel ≥ 2 °C)

### Nacht-Kühlung (nur abend + nacht)

Alle Bedingungen müssen gelten:

- `binary_sensor.helios_bypass` = on (Sommer)
- `co2_effektiv` ≤ 1000 ppm
- Schlafzimmer-Temp − Außen-Temp ≥ 2 °C

→ **15 %** (`grund_code: nacht_kuehlung`)

### Radon (optional, `radon_logic_enabled`)

| Radon | Ziel % |
|-------|--------|
| > Schwellwert (95) | 75 |
| > Boost (110) | 100 |

## Status-Sensor (`sensor.luftung_status`)

| `grund_code` | Anzeige (state) |
|--------------|-----------------|
| `notaus` | Not-Aus aktiv |
| `sensor_ausfall` | CO₂-Sensor fehlt |
| `co2_sehr_hoch` | CO₂ sehr hoch |
| `co2_hoch` | CO₂ hoch |
| `co2_erhoht` | CO₂ erhöht |
| `co2_leicht` | CO₂ leicht erhöht |
| `co2_hitze_sperre` | CO₂ erhöht — Sommer-Hitze-Sperre |
| `radon_boost` | Radon kritisch |
| `radon_warn` | Radon erhöht |
| `nacht_kuehlung` | Nacht-Kühlung (außen kühler) |
| `aus` | Aus — alles ok |

Attribute: `ziel_prozent`, `profil`, `co2_schlafzimmer`, `co2_effektiv`, `aussen_temp`, `innen_temp`, `delta_temp`, `bypass_aktiv`.

## Automationen

| ID | Alias | Rolle |
|----|-------|-------|
| `ventilation_notaus` | Lüftung: Not-Aus | Sofort 0 % bei Not-Aus; auch bei manueller Änderung am Lüfter; alle 5 min nachhalten |
| `ventilation_auto_co2_control` | Lüftung: Zentrale Steuerung | Setzt `fan.helios` auf `ziel_prozent` aus Status-Sensor |

## Randfälle

- **Not-Aus an:** Lüfter immer 0 %, auch wenn CO₂ hoch oder Helios-UI dreht
- **Not-Aus aus:** Steuerung übernimmt wieder innerhalb 5 min
- **CO₂-Sensor einzeln offline:** `house_max_co2` aus verfügbaren Sensoren; mindestens Schlafzimmer reicht
- **Winter (Bypass aus):** Keine Nacht-Kühlung, nur CO₂/Radon
- **Manuell am Helios:** Nächster Automations-Lauf (≤5 min) setzt Sollwert wieder

## UI

- **Steuerung:** Dashboard **Übersicht** → Lüftungszentrale (`sensor.luftung_status`, Not-Aus)
- **Analyse / Verlauf:** Dashboard **Lüftung** (`/dashboard-luftung`) — CO₂, Temperatur, Lüfterstufen über 24 h und 7 Tage — siehe [`dashboard-luftung.md`](./dashboard-luftung.md)

## Abnahme

- [ ] `sensor.house_max_co2` nicht dauerhaft `unavailable`
- [ ] `sensor.luftung_status` zeigt plausiblen Grund bei CO₂-Anstieg
- [ ] Not-Aus: Lüfter sofort aus, bleibt aus
- [ ] Nacht: bei hohem Schlafzimmer-CO₂ steigt Lüfter an
- [ ] Sommer-Nacht: bei kühler Außenluft + gutem CO₂ → „Nacht-Kühlung“
