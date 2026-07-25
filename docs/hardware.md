## AI-on-the-Edge (Zähler)

Zwei ESP32-CAM-Geräte mit [AI-on-the-Edge](https://github.com/jomjol/AI-on-the-edge-device) lesen Gas- und Wasserzähler per Kamera aus.

| Gerät | MQTT-ID | Web-UI (LAN) | HA-Haupt-Entity | Stand Abgleich 2026-05-27 |
|-------|---------|--------------|-------------------|---------------------------|
| Gaszähler | `gasmeter` | http://192.168.188.122/ | `sensor.gasmeter_value` | ✅ aktiv (~9970,9 m³) |
| Wasserzähler | `watermeter` | http://192.168.188.121/ | `sensor.watermeter_value_stabil` (Energie; Roh: `sensor.watermeter_value`) | ✅ aktiv (~150 m³) |

Details: [`ai-on-the-edge.md`](./ai-on-the-edge.md)

## Dimmer

Der Markt für Licht Dimmer mit Zigbee Basis ist sehr kompliziert. Die meisten Hardware Komponenten erfordern, dass der Dimmer zwischen die Lampe geschaltet wird (um Strom zu erhalten). Dies ist jedoch nicht das gewünschte Verhalten. 

Ich teste nun "SLC SmartOne ZigBee 4in1 Wandschalter Wanddimmer" von Lampenwelt

## Friends of Hue

Die Schalter sind leider noch nicht gut genug, manchmal muss man mehrfach drücken, gefällt mir nicht.

**Hue Smart Button (David/Adrian):** Gehäuse kann die Taste klemmen — Adrian-klein nur zuverlässig mit leicht offenem Case. Details: [`lights.md`](lights.md) → Abschnitt „Hue Smart Button — Montage & Diagnose“.

## Garten-Bewässerung

| Komponente | Modell / Name | Integration | Status |
|------------|---------------|-------------|--------|
| Gateway Bodenfeuchte | **froggit DP1500** (≈ Ecowitt GW1100A) | Core **`ecowitt`** | ✅ Web-UI `http://192.168.188.166/`, 8× CH |
| Bodenfeuchte Garten + innen | **froggit DP100** (868 MHz, max. 8×) | über DP1500 → `sensor.gw1100a_soil_moisture_1` … `_8` | ✅ 8 Kanäle live — **CH5–CH7 Garten** (Beet, Hecke, Himbeeren), **CH1–CH4 + CH8 Topfpflanzen** |
| Bodenfeuchte Hecke/Beet (Zigbee, alt.) | Tuya SGS01Z / TS0601 | Zigbee2MQTT | 📦 optional parallel |
| Ventil Rasen gross | Gardena 1285-20 BT | `gardena_bluetooth` (Proxy Fix) | ✅ Zone A, `valve.ventil_garten_rasen_gross` |
| Ventil Rasen klein | Gardena 1285-20 BT | `gardena_bluetooth` (Proxy Fix) | ✅ Zone B, `valve.ventil_garten_rasen_klein` |
| Ventil Tropf Hecke/Beet | Gardena 1285-20 BT | `gardena_bluetooth` (Proxy Fix) | ✅ Zone C, `valve.ventil_garten_tropf_hecke_beet` *(Leck repariert 2026-07-25)* |
| BT-Proxy EG Garten | M5 Atom Lite | ESPHome `atom-bluetooth-proxy-eg-garten.yaml` | ✅ **active scanning**, am EG-Fenster |
| BT-Proxy 1.OG / 2.OG | M5 Atom Lite | ESPHome | ✅ passiv |

Einrichtung DP1500 → HA und **Kanal-Tabelle** (CH1–CH8): [`garten-bewaesserung.md`](./garten-bewaesserung.md#froggit-dp1500--home-assistant-ecowitt).

| CH | Standort | Pflanze | Kurz |
|----|----------|---------|------|
| 1 | Zimmer Adrian (1.OG) | Glücksfeder (klein) | 2× Glücksfeder Adrian |
| 2 | Wohnzimmer | Elefantenfuß | |
| 3 | Esszimmer | Strahlenaralie | |
| 4 | Zimmer Adrian (1.OG) | Glücksfeder (groß) | 2× Glücksfeder Adrian |
| 5 | Garten Beet | — | Regner + Tropf erreichen Messstelle |
| 6 | Garten Hecke | — | Tropf Zone C, Tropf-Automation |
| 7 | Garten Himbeeren | Himbeeren | Regner + Tropf erreichen Messstelle |
| 8 | Zimmer David | Glücksbambus | |

## Bodenfeuchte innen (Topfpflanzen)

| Komponente | Modell | Integration | Status |
|------------|--------|-------------|--------|
| Topfpflanzen (5×) | **froggit DP100** über DP1500 | Ecowitt — CH1–CH4, CH8 | ✅ live — siehe Kanal-Tabelle oben |
| Topfpflanze (optional) | ThirdReality 3RSM0147Z / Gen2 | Zigbee2MQTT | 📦 1× offen — parallel/Reserve |

Nur Monitoring — **keine** Garten-Automation. Vollständige Zuordnung + Friendly-Name-Vorschläge: [`garten-bewaesserung.md`](./garten-bewaesserung.md).

**Legacy (ohne Smart Gateway nicht nutzbar):** GARDENA smart Sensor — ersetzen durch Zigbee; `gardena_smart_system` in HA entfernen.