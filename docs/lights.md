# Licht Gruppen




## Einzellichter

| Entity ID | Name | Ort | Typ | Features |
| :--- | :--- | :--- | :--- | :--- |
| `light.licht_eg_wohnzimmer_regal` | Licht-EG-Wohnzimmer-Regal | Wohnzimmer (EG) | Switch | dimmbar |
| `light.licht_eg_esszimmer_schrank` | Licht-EG-Esszimmer-Schrank | Esszimmer (EG) | Switch | dimmbar |
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
| `light.licht_eg_wohnzimmer_tv_led` | Licht-EG-Wohnzimmer-TV-LED | Global | Switch | dimmbar |
| `light.licht_eg_wohnzimmer_couch_led` | Licht-EG-Wohnzimmer-Couch-LED | Global | Switch | dimmbar |


## 📦 Lichtgruppen
| Entity ID | Name | Ort | Mitglieder |
| :--- | :--- | :--- | :--- |
| `light.hauptlicht_esszimmer` | Hauptlicht Esszimmer | Global | light.licht_eg_esszimmer_lang, light.licht_eg_esszimmer_spot1, light.licht_eg_esszimmer_spot2, light.licht_eg_esszimmer_spot3, light.licht_eg_esszimmer_spot4, light.licht_eg_esszimmer_schrank |
| `light.hauptlicht_wohnzimmer` | Hauptlicht Wohnzimmer | Global | light.licht_eg_wohnzimmer_spot1, light.licht_eg_wohnzimmer_spot2, light.licht_eg_wohnzimmer_spot3, light.licht_eg_wohnzimmer_zentral, light.licht_eg_wohnzimmer_iris, light.licht_eg_wohnzimmer_couch_led, light.licht_eg_wohnzimmer_tv_led, light.licht_eg_wohnzimmer_regal |
| `light.alle_lichter_esszimmer` | Alle Lichter Esszimmer | Global | light.hauptlicht_esszimmer, light.licht_eg_esszimmer_schrank |
| `light.alle_lichter_wohnzimmer` | Alle Lichter Wohnzimmer | Global | light.hauptlicht_wohnzimmer, light.licht_eg_wohnzimmer_iris, light.licht_eg_wohnzimmer_regal |
| `light.alle_lichter_erdgeschoss` | Alle Lichter Erdgeschoss | Global | light.alle_lichter_esszimmer, light.alle_lichter_wohnzimmer, light.licht_eg_kueche |


## 🎮 Licht Controller

Wichtig für KI-Automationen: Diese Schalter liefern über ihre primäre Entity ID meist nur den Batteriestatus. Für die Logik müssen Device Triggers mit der jeweiligen device_id verwendet werden.

###  Licht-Controller (MQTT Device Triggers)

| Name | Entity ID | Type | MQTT ID | Aktionen |
| :--- | :--- | :--- | :--- | :--- |
| Schalter-EG-Licht-Drehregler-Esszimmer| `sensor.XXX` | Hue Unterputz single_rocker | `3e21bd5e019491ad1af4eefc4868de11` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-EG-Esszimmer-Tuere-Schalter2 | `sensor.schalter_eg_esszimmer_tuere_schalter2_battery` | Hue Unterputz single_rocker | `f3f56a37a0a48b3897df52de23d30a29` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-EG-Esszimmer-Tuere-Schalter3 | `sensor.schalter_eg_esszimmer_tuere_schalter3_battery` | Hue Unterputz single_rocker | `489d632330420a07586faaa8b0ae6629` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-EG-Esszimmer-Tuere-Schalter4 | `sensor.schalter_eg_esszimmer_tuere_schalter4_battery` | Hue Unterputz single_rocker | `01c59c2f89281f09be49aae80825ad32` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-EG-Kueche-Tuere | `sensor.schalter_eg_kueche_tuere_battery` | Hue Unterputz single_rocker | `76be11dcc3a6cd381df514d76309bb40` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-EG-Esszimmer-Tuere-8fach | `sensor.schalter_eg_esszimmer_tuere_8fach_battery` | EcoDim (Zigbee 8 button) | `81ba3f8b1dc7583b21bf87aabad6c836` | `on_1..4`, `off_1..4`, `brightness_move_down_1..4`, `brightness_move_up_1..4`, `brightness_stop_1..4` |
| Schalter-EG-HueDimmerSwitch | `sensor.schalter_eg_huedimmerswitch_battery` | Hue Dimmer | `0457441d0c73d8db61464dce69f22ef2` | `on_press/hold/release`, `up_press/hold/release`, `down_press/hold/release`, `off_press/hold/release` |
| Schalter-1OG-David-Tuere | `sensor.schalter_1og_david_tuere_battery` | Hue Unterputz single_rocker | `eb9176b54c72cdc77763504806f72acd` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-1OG-David-klein | `sensor.schalter_1og_david_klein_battery` | Hue Smart Button | `2e0440a811764f5a442354a22f8191f5` | `on`, `off`, `press`, `release`, `hold`, `brightness_step_up`, `brightness_step_down` |
| Schalter-1OG-Adrian-Tuere | `sensor.schalter_1og_adrian_tuere_battery` | Hue Unterputz single_rocker | `57a44c1d926b3e4c1e7092c179feb5e3` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-2OG-Schlafzimmer-Bett | `sensor.schalter_2og_schlafzimmer_bett_battery` | Hue Unterputz single_rocker | `684dfe33d7c759e0ab160a5a9da701af` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |
| Schalter-2OG-Schlafzimmer-Tuere | `sensor.schalter_2og_schlafzimmer_tuere_battery` | Hue Unterputz single_rocker | `630f348ce74ce1b95aa5fc5b75898785` | `left_press`, `left_hold`, `left_press_release`, `left_hold_release` |


### Beispiel Implementierung:
```
trigger:
  - device_id: 489d632330420a07586faaa8b0ae6629 # Schalter-EG-Esszimmer-Tuere-Schalter3
    domain: mqtt
    type: action
    subtype: left_hold
    platform: device
```

(verwendeter Befehl in Homeassistant)

```jinja2
### 📦 Lichtgruppen
| Entity ID | Name | Ort | Mitglieder |
| :--- | :--- | :--- | :--- |
{% for state in states.light if state.attributes.entity_id is defined -%}
| `{{ state.entity_id }}` | {{ state.attributes.friendly_name }} | {{ area_name(state.entity_id) or 'Global' }} | {{ state.attributes.entity_id | join(', ') }} |
{% endfor %}

| Entity ID | Name | Ort | Typ | Features |
| :--- | :--- | :--- | :--- | :--- |
{% for state in states.light if state.attributes.entity_id is not defined -%}
| `{{ state.entity_id }}` | {{ state.attributes.friendly_name }} | {{ area_name(state.entity_id) or 'Global' }} | {{ state.attributes.color_mode or 'Switch' }} | {{ 'dimmbar' if state.attributes.supported_color_modes is defined else 'an/aus' }} |
{% endfor %}
```