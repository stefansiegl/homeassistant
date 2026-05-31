# EG-Licht: Anforderungen & Szenen-Konzept

Spec für Beleuchtung Erdgeschoss (Küche, Esszimmer, Wohnzimmer). Implementierung: [`scenes.yaml`](../scenes.yaml), [`scripts.yaml`](../scripts.yaml), [`automations.yaml`](../automations.yaml).

Verwandt: [`licht-drehregler-eg.md`](licht-drehregler-eg.md), [`lights.md`](lights.md).

---

## Personas

| Person | Szenen | LED-Streifen | Anmerkung |
|--------|--------|--------------|-----------|
| **Stefan** | **Hell**, **Gemütlich** (bestehend) — unverändert | In Gemütlich dezent ok | Brettspiele, Kino bleiben |
| **Kathi** | **Kathi Gemütlich**, **Kathi Ess** (neu) | Immer aus | Glühbirnen-Flair, 2700K, nicht orange |

---

## Lampen EG (15 Einzellichter)

Siehe [`lights.md`](lights.md). Schrank Ess = Hue-Steckdose (nur On/Off).

**Dimmbar Ess (Drehregler):** `lang`, `spot1`–`spot4` — ohne Schrank.

---

## Szenen-Katalog

### Stefan (unverändert)

| Szene | ID | 8-fach |
|-------|-----|--------|
| Gemütlich | `eg_entspannter_abend` | on_1 |
| Hell | `eg_hell` | on_2 |
| Brettspiele | `eg_brettspiele` | on_3 |
| Kino | `eg_kino` | — (Hue-Dimmer-Zyklus) |
| Sonnenuntergang | `eg_sonnenuntergang` | — (Hue-Dimmer-Zyklus) |

### Kathi (neu)

| Szene | ID | 8-fach | Beschreibung |
|-------|-----|--------|--------------|
| Kathi Gemütlich | `eg_kathi_gemuetlich` | on_4 | lang + zentral + iris, 2700K, gedimmt, keine Streifen |
| Kathi Ess | `eg_kathi_ess` | — | Nur Ess, lang + Spot2/3 schwach |

Alte Referenz-Szenen `Kathi 1/2/3` bleiben parallel.

### Design Kathi: „Glühbirne, nicht orange“

- **2700K** (nie 2400K/1800K)
- Helligkeit **50–80/255**
- Wenige Lampen gleichzeitig (indirekt statt alle Spots)
- Kein `rgb_color`

---

## Drei Ebenen Bedienlogik

1. **Szene** (8-fach, Hue-Dimmer) → Gesamtbild; `input_select.aktive_szene_eg` merkt sich die Szene
2. **Raum-Schalter** → Aus, oder **Neutralwert** beim Wieder-An (tageszeitabhängig)
3. **Drehregler** → Feintuning Helligkeit (absolut), siehe [`licht-drehregler-eg.md`](licht-drehregler-eg.md)

**Szene erneut** → stellt volles Szenenbild wieder her.

---

## Raum-Schalter — Neutralwert

**Aus:** Raum-Gruppe aus; aktive Szene bleibt gespeichert.

**Wieder an:** Script `licht_eg_raum_ein` — nicht Szene-Anteil, sondern Neutralwert:

| Raum | Abends (Sonne unter Horizont) | Tagsüber |
|------|-------------------------------|----------|
| Küche | 40 % (~102), 2700K | 80 % (~204), 2700K |
| Ess (dimmbar + Schrank) | lang 50 %, Spots aus, Schrank an | lang 70 %, Spots aus, Schrank an |
| Wohn (hauptlicht + iris) | zentral 45 %, iris 55 %, Streifen aus | zentral 60 %, iris 70 %, Streifen aus |

LED-Streifen im Neutralwert standardmäßig **aus**.

---

## Schalter-Zuordnung (Automation)

| Gerät | device_id | Kurzdruck |
|-------|-----------|-----------|
| Schalter-EG-Küche-Tuere | `76be11dc…` | Küche Neutral/Toggle |
| Schalter-EG-Esszimmer-Tuere-Schalter2 | `f3f56a37…` | Küche (parallel zu Küche-Tür) |
| Schalter-EG-Esszimmer-Tuere-Schalter3 | `489d6323…` | Ess Neutral/Toggle |
| Schalter-EG-Esszimmer-Tuere-Schalter4 | `01c59c2f…` | Wohn Neutral/Toggle |
| Schalter-EG-Licht-Drehregler-Esszimmer | `3e21bd5e…` | Test: dimmbar Ess (parallel zu Schalter3) |
| Schalter-EG-Esszimmer-Tuere-8fach | `81ba3f8b…` | Szenen + EG aus + Dim |
| Schalter-EG-HueDimmerSwitch | `0457441d…` | Szenen-Zyklus + EG dim/aus |

**Rollout Drehregler:** Test parallel zu Schalter3 → bei Abnahme Rocker ausbauen.

---

## Helfer

- `input_select.szenen_zyklus_eg` — Hue-Dimmer-Zyklus (inkl. Kathi Gemütlich)
- `input_select.aktive_szene_eg` — zuletzt aktive EG-Szene (8-fach / Dimmer)

Ess-Drehregler: lang + spot1–4 — gleiche **color_temp_kelvin** bei jedem Befehl (übernimmt von bereits an leuchtendem Spot, sonst 4000K).

---

## Fallback ohne Home Assistant

Siehe [`zigbee-schalter-ohne-ha.md`](zigbee-schalter-ohne-ha.md). Kurz: **Zigbee2MQTT-Bindings** für Basis On/Off; Szenen/Neutralwert/Drehregler-Logik nur mit HA.

---

## Abnahme

- [ ] Kathi Gemütlich / Kathi Ess abends mit Kathi testen
- [ ] Drehregler: Drehen + Klick bei Szene, App, anderem Schalter
- [ ] Raum-Schalter: Aus → wieder an = Neutralwert, Szene neu = volles Bild
