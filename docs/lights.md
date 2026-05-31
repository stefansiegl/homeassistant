# Licht Gruppen

Spec EG-Beleuchtung: [`licht-eg-anforderungen.md`](licht-eg-anforderungen.md) · Drehregler: [`licht-drehregler-eg.md`](licht-drehregler-eg.md)

## Einzellichter

| Entity ID | Name | Ort | Typ | Features |
| :--- | :--- | :--- | :--- | :--- |
| `light.licht_eg_wohnzimmer_regal` | Licht-EG-Wohnzimmer-Regal | Wohnzimmer (EG) | Switch | Steckdose (On/Off) |
| `light.licht_eg_esszimmer_schrank` | Licht-EG-Esszimmer-Schrank | Esszimmer (EG) | Switch | **Hue-Steckdose** (On/Off, kein Dimmen über Lampe) |
| `light.licht_eg_kueche` | Licht-EG-Kueche | Küche (EG) | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_iris` | Licht-EG-Wohnzimmer-Iris | Wohnzimmer (EG) | Switch | dimmbar |
| `light.licht_eg_esszimmer_lang` | Licht-EG-Esszimmer-lang | Esszimmer (EG) | Switch | dimmbar |
| `light.licht_eg_esszimmer_spot1` | Licht-EG-Esszimmer-Spot1 | Esszimmer (EG) | Switch | dimmbar |
| `light.licht_eg_esszimmer_spot2` | Licht-EG-Esszimmer-Spot2 | Esszimmer (EG) | Switch | dimmbar |
| `light.licht_eg_esszimmer_spot3` | Licht-EG-Esszimmer-Spot3 | Esszimmer (EG) | Switch | dimmbar |
| `light.licht_eg_esszimmer_spot4` | Licht-EG-Esszimmer-Spot4 | Esszimmer (EG) | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_zentral` | Licht-EG-Wohnzimmer-zentral | Wohnzimmer (EG) | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_spot1` | Licht-EG-Wohnzimmer-Spot1 | Wohnzimmer (EG) | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_spot2` | Licht-EG-Wohnzimmer-Spot2 | Wohnzimmer (EG) | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_spot3` | Licht-EG-Wohnzimmer-Spot3 | Wohnzimmer (EG) | Switch | dimmbar |
| `light.licht_1og_david` | Licht-1OG-David | david | Switch | dimmbar |
| `light.licht_1og_adrian` | Licht-1OG-Adrian | Adrian | xy | dimmbar |
| `light.licht_2og_schlafzimmer` | Licht-2OG-Schlafzimmer | Schlafzimmer (2. OG) | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_tv_led` | Licht-EG-Wohnzimmer-TV-LED | Global | Switch | dimmbar (RGB+CCT) |
| `light.licht_eg_wohnzimmer_couch_led` | Licht-EG-Wohnzimmer-Couch-LED | Global | Switch | dimmbar (RGB+CCT) |


## 📦 Lichtgruppen

| Entity ID | Name | Ort | Mitglieder |
| :--- | :--- | :--- | :--- |
| `light.hauptlicht_esszimmer` | Hauptlicht Esszimmer | Global | lang, spot1–4, schrank |
| `light.hauptlicht_wohnzimmer` | Hauptlicht Wohnzimmer | Global | spot1–3, zentral, iris, couch_led, tv_led, regal |
| `light.alle_lichter_esszimmer` | Alle Lichter Esszimmer | Global | hauptlicht_esszimmer, schrank *(Doppelung schrank möglich — in HA-UI prüfen)* |
| `light.alle_lichter_wohnzimmer` | Alle Lichter Wohnzimmer | Global | hauptlicht_wohnzimmer, iris, regal |
| `light.alle_lichter_erdgeschoss` | Alle Lichter Erdgeschoss | Global | alle_lichter_esszimmer, alle_lichter_wohnzimmer, kueche |

**Drehregler Ess:** lang + spot1–4 · **Drehregler Wohn:** zentral + spot1–3 (Aus = `alle_lichter_wohnzimmer`).

Fallback ohne HA: [`zigbee-schalter-ohne-ha.md`](zigbee-schalter-ohne-ha.md)

Sprachsteuerung (Google/Assist): [`sprachsteuerung-licht-eg.md`](sprachsteuerung-licht-eg.md)


## 🎮 Licht-Schalter (Controller)

Wichtig für Automationen: **Device Triggers** mit `device_id` (nicht nur Batterie-Sensor). MQTT-Topic in Z2M: `zigbee2mqtt/<friendly_name>`.

Spec EG: [`licht-eg-anforderungen.md`](licht-eg-anforderungen.md) · Drehregler: [`licht-drehregler-eg.md`](licht-drehregler-eg.md) · Fallback ohne HA: [`zigbee-schalter-ohne-ha.md`](zigbee-schalter-ohne-ha.md)

### Erdgeschoss (EG)

| Name (Z2M) | Batterie | Typ | device_id | MQTT-Aktionen | Automation / Wirkung |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Schalter-EG-Licht-Drehregler-Esszimmer | `sensor.schalter_eg_licht_drehregler_esszimmer_battery` | The Light Group S57018 | `3e21bd5e019491ad1af4eefc4868de11` | `brightness_move_to_level`, `on`/`off` + `action_level` | Drehen/Klick → `lang` + Spot1–4 (gleiche Kelvin) · `Licht: Drehregler Esszimmer` |
| Schalter-EG-Licht-Drehregler-Wohnzimmer | `sensor.schalter_eg_licht_drehregler_wohnzimmer_battery` | The Light Group S57018 | `d8c9bfd63856abadac3f5c78933eac38` | wie Ess-Drehregler | An/dim → `zentral` + Spot1–3 · Aus-Klick → `alle_lichter_wohnzimmer` · `Licht: Drehregler Wohnzimmer` |
| Schalter-EG-Kueche-Tuere | `sensor.schalter_eg_kueche_tuere_battery` | Hue wall switch module | `76be11dcc3a6cd381df514d76309bb40` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` | Küche Toggle/Neutral · `Lichtschalter-EG-Küche-Tür` |
| Schalter-EG-Esszimmer-Tuere-Schalter2 | `sensor.schalter_eg_esszimmer_tuere_schalter2_battery` | Hue wall switch module | `f3f56a37a0a48b3897df52de23d30a29` | wie Küche-Tür | Küche Toggle/Neutral · `Lichtschalter-EG-Esszimmer-Tuere-02` · **Trigger:** `left_press_release` + 400 ms Debounce (mehrfache Events nach Einbau) · **Z2M-Bindings** zu `Licht-EG-Kueche` entfernen |
| Schalter-EG-Esszimmer-Tuere-Schalter3 | `sensor.schalter_eg_esszimmer_tuere_schalter3_battery` | Hue wall switch module | `489d632330420a07586faaa8b0ae6629` | wie Küche-Tür | Ess Toggle/Neutral · parallel zu Drehregler · **später Ausbau** · `Lichtschalter-EG-Esszimmer-Tuere-03` |
| Schalter-EG-Esszimmer-Tuere-Schalter4 | `sensor.schalter_eg_esszimmer_tuere_schalter4_battery` | Hue wall switch module | `01c59c2f89281f09be49aae80825ad32` | wie Küche-Tür | Wohn Toggle/Neutral · `Lichtschalter-EG-Esszimmer-Tuere-04` |
| Schalter-EG-Esszimmer-Tuere-8fach | `sensor.schalter_eg_esszimmer_tuere_8fach_battery` | EcoDim ED-10014 | `81ba3f8b1dc7583b21bf87aabad6c836` | `on_1..4`, `off_1..4`, `brightness_move_up/down_1..4`, `brightness_stop_1..4` | Szenen + EG aus + Dim · `Beleuchtung: 8-Fach Schalter Erdgeschoss` |
| Schalter-EG-HueDimmerSwitch | `sensor.schalter_eg_huedimmerswitch_battery` | Hue Dimmer Switch Gen2 | `0457441d0c73d8db61464dce69f22ef2` | `on/off/up/down` × `press/hold/release` | Szenen-Zyklus, EG dim/aus · `Licht: Hue Dimmer Switch EG komplett` |

#### 8-fach — Szenen-Mapping

| Taste | Szene |
|-------|-------|
| on_1 | Gemütlich |
| on_2 | Hell |
| on_3 | Brettspiele |
| on_4 | Kathi Gemütlich |
| off_1–4 | EG aus (`alle_lichter_erdgeschoss`) |

#### Hue Dimmer EG — Kurzübersicht

| Taste / Geste | Wirkung |
|---------------|---------|
| Szene-Taste (`off_press`) | Nächste Szene aus `input_select.szenen_zyklus_eg` |
| Power halten (`on_hold`) | Ganzes EG aus |
| Hoch/Runter (press/hold) | Aktive EG-Lichter heller/dunkler |

---

### 1. Obergeschoss (David & Adrian)

| Name (Z2M) | Batterie | Typ | device_id | MQTT-Aktionen | Automation / Wirkung |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Schalter-1OG-David-Tuere | `sensor.schalter_1og_david_tuere_battery` | Hue wall switch module | `eb9176b54c72cdc77763504806f72acd` | `left_press`, `left_hold`, `left_hold_release` | Klick Toggle · Hold = dimmen · `David: Kombinierte Steuerung` |
| Schalter-1OG-David-klein | `sensor.schalter_1og_david_klein_battery` | Hue Smart Button | `2e0440a811764f5a442354a22f8191f5` | `press`, `hold`, `release` | Klick Toggle · Hold = dimmen · Ziel: `light.licht_1og_david` · dieselbe Automation |
| Schalter-1OG-Adrian-Tuere | `sensor.schalter_1og_adrian_tuere_battery` | Hue wall switch module | `57a44c1d926b3e4c1e7092c179feb5e3` | `left_press` | Einfachklick Toggle · Doppelklick Szenen Hell/Gemütlich · `Adrian: Kombinierte Steuerung` |
| Schalter-1OG-Adrian-klein | `sensor.schalter_1og_adrian_klein_battery` | Hue Smart Button | `e04e1bc520552046b664e45a54a136f1` | `press`, `hold`, `release` | Klick Toggle · Hold = dimmen · Ziel: `light.licht_1og_adrian` · **Gehäuse:** siehe Abschnitt unten |

#### Hue Smart Button — Montage & Diagnose

Gilt für **David-klein** und **Adrian-klein** (Philips Hue Smart Button, Z2M).

| Symptom | Typische Ursache |
|---------|------------------|
| In Z2M nur `hold` / `brightness_step_down`, kein sauberes `press` → `release` → `on`/`off` | Gehäuse drückt die Taste dauerhaft oder schließt zu stramm |
| Lampe dimmt endlos / Automation „hängt“ im Hold-Loop | wie oben + ggf. Zigbee-Binding auf Lampe (in Z2M **Bind** prüfen) |
| Toggle in HA reagiert nicht, MQTT wirkt „kaputt“ | oft mechanisch, nicht Automation — Z2M-Log auf vollständige Drucksequenz prüfen |

**Adrian-klein (Stand 2026-05):** Funktioniert zuverlässig nur, wenn das **Gehäuse nicht ganz zugeschraubt** ist — bei vollem Zu zieht das Case die Taste und simuliert Halten.

**Montage-Hinweise:**

- Gehäuse nicht maximal anziehen; nach dem Einsetzen in Z2M kurzdrücken und Sequenz `press` → `release` → `on`/`off` erwarten (wie David-klein).
- Keine direkten **Zigbee-Bindings** auf die Zimmerlampe — Steuerung läuft über HA (`Adrian: Kombinierte Steuerung` / `David: Kombinierte Steuerung`).
- Bei Re-Pairing: Bindings in Z2M prüfen und entfernen.

---

### 2. Obergeschoss (Schlafzimmer)

| Name (Z2M) | Batterie | Typ | device_id | MQTT-Aktionen | Automation / Wirkung |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Schalter-2OG-Schlafzimmer-Tuere | `sensor.schalter_2og_schlafzimmer_tuere_battery` | Hue wall switch module | `630f348ce74ce1b95aa5fc5b75898785` | `left_press`, … | Toggle `light.licht_2og_schlafzimmer` (40 %) · `Lichtschalter-2OG-Schlafzimmer-bett&tuere` |
| Schalter-2OG-Schlafzimmer-Bett | `sensor.schalter_2og_schlafzimmer_bett_battery` | Hue wall switch module | `684dfe33d7c759e0ab160a5a9da701af` | `left_press`, … | wie Tür · dieselbe Automation |

---

### Beispiel Device Trigger (YAML)

```yaml
trigger:
  - trigger: device
    domain: mqtt
    device_id: 489d632330420a07586faaa8b0ae6629  # Schalter-EG-Esszimmer-Tuere-Schalter3
    type: action
    subtype: left_press
```

Drehregler (JSON auf State-Topic, nicht Device-Trigger für `action_level`):

```yaml
trigger:
  - trigger: mqtt
    topic: zigbee2mqtt/Schalter-EG-Licht-Drehregler-Esszimmer
```
