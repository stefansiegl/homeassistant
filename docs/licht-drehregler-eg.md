# Drehregler EG — Schalter-EG-Licht-Drehregler-Esszimmer

Spec für den **neuen** Zigbee-Drehregler (The Light Group S57018). Parallel zum bestehenden Hue single_rocker (Schalter3) bis Ausbau.

Implementierung: [`scripts.yaml`](../scripts.yaml), Automation `Licht: Drehregler Esszimmer` in [`automations.yaml`](../automations.yaml).

---

## Gerät

| Feld | Wert |
|------|------|
| friendly_name (Z2M) | `Schalter-EG-Licht-Drehregler-Esszimmer` |
| IEEE | `0x842e14fffee721e6` |
| HA device_id | `3e21bd5e019491ad1af4eefc4868de11` |
| Hersteller | The Light Group AS |
| Modell | S57018 |
| Batterie-Entity | `sensor.schalter_eg_licht_drehregler_esszimmer_battery` |

**Nicht verwechseln** mit Hue Unterputz single_rocker (`left_press`) — der bleibt bis Ausbau an Schalter3.

---

## MQTT-Verhalten (Zigbee2MQTT)

Payload auf Topic `zigbee2mqtt/Schalter-EG-Licht-Drehregler-Esszimmer`:

### Regler drehen

```json
{
  "action": "brightness_move_to_level",
  "action_level": 214,
  "action_transition_time": 0
}
```

| Eigenschaft | Wert |
|-------------|------|
| `action_level` min | **1** |
| `action_level` max | **249** (Schrittweite **3**: 1, 4, 7, … 249) |
| Maximum-Position | `action_level` = **`null`** |

### Kurz-Klick

```json
{
  "action": "on",
  "action_level": 240,
  "action_transition_time": 0
}
```

- `action` wechselt **abwechselnd** `on` / `off` — interner Zähler, **nicht** zuverlässig Raum-Zustand
- `action_level` = aktuelle **Regler-Position** (absolute Helligkeit)

---

## Design-Quirks

1. **Absolute Werte** — kein relatives step up/down wie Hue Dimmer oder 8-fach-Schalter
2. **Kein Sync** — Regler kennt nicht, wenn App/Szene/anderer Schalter Helligkeit ändert
3. **Nächstes Drehen** springt auf Regler-Position — erwartetes Verhalten, kein Bug

---

## Mapping → Home Assistant

```
action_level null  → brightness 255
action_level 1–249 → brightness = action_level (1:1)
```

Ziel-Entities (dimmbar Ess):

- `light.licht_eg_esszimmer_lang`
- `light.licht_eg_esszimmer_spot1` … `spot4`

Schrank-Steckdose **nicht** im Drehregler-Scope.

---

## Umsetzungslogik

### Drehen (`brightness_move_to_level`)

- `light.turn_on` auf Ziel-Entities mit gemappter `brightness`
- Licht war aus → einschalten auf Regler-Position
- Aktive Szene in `input_select.aktive_szene_eg` **bleibt** (Feintuning Ebene 3)

### Klick (`on` oder `off`)

- **`action` ignorieren**
- Wenn **irgendein** Ziel-Licht in HA an → `light.turn_off`
- Sonst → `light.turn_on` mit Helligkeit aus `action_level`

### Trigger in HA

MQTT-Trigger auf `zigbee2mqtt/Schalter-EG-Licht-Drehregler-Esszimmer`, JSON-Felder `action` und `action_level` auswerten (Device-Trigger liefert `action_level` nicht zuverlässig mit).

---

## Bekannte Situationen

| Situation | Ergebnis |
|-----------|----------|
| Helligkeit per App geändert | Nächstes Drehen = Regler-Position |
| Szene aktiviert | Erstes Drehen setzt absolute Stufe |
| Anderer Schalter schaltet aus | Klick am Regler schaltet an (HA-basiert) |
| Anderer Schalter schaltet an | Klick schaltet aus (HA-basiert) |

---

## Schalter-EG-Licht-Drehregler-Wohnzimmer

| Feld | Wert |
|------|------|
| friendly_name (Z2M) | `Schalter-EG-Licht-Drehregler-Wohnzimmer` |
| IEEE | `0x842e14fffee7220f` |
| HA device_id | `d8c9bfd63856abadac3f5c78933eac38` |
| MQTT-Topic | `zigbee2mqtt/Schalter-EG-Licht-Drehregler-Wohnzimmer` |

MQTT-Verhalten wie Ess-Regler.

| Aktion | Ziel |
|--------|------|
| Drehen / Klick An | `zentral`, `spot1`–`spot3` |
| Klick Aus (wenn irgendwas Wohn an) | `light.alle_lichter_wohnzimmer` |

Scripts: `licht_wohn_drehregler_*` · Automation: `Licht: Drehregler Wohnzimmer`

---

## Fallback ohne Home Assistant

Siehe [`zigbee-schalter-ohne-ha.md`](zigbee-schalter-ohne-ha.md).
