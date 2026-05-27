# Log-Audit (Home Assistant)

Überblick wiederkehrender Meldungen in den Core-Logs und was dagegen getan wurde bzw. getan werden kann.

## Behoben (Repo/YAML)

| Meldung | Ursache | Fix |
|---------|---------|-----|
| `Error initializing 'Sicherheit: Radon Alarm (Kritisch)'` — State `'good'` cannot be processed as a number | Trigger nutzte `sensor.airthings_wave2_181676_radon_1_tages_wert` (Enum-Stufe, kein Bq/m³) | Automation → `sensor.airthings_wave2_181676_radon_1_tages_durchschnitt` |
| `Template loop detected` für `sensor.batterie_ubersicht` | Legacy-Template aktualisierte sich selbst bei jedem State-Change | Trigger-Template mit Filter (ignoriert eigene Entity) |

### Radon-Entities (Airthings Wave Küche)

| Entity | Typ | Verwendung |
|--------|-----|------------|
| `sensor.airthings_wave2_181676_radon_1_tages_durchschnitt` | Zahl (Bq/m³) | Schwellwert-Automationen |
| `sensor.airthings_wave2_181676_radon_1_tages_wert` | Enum (`good`, …) | Nur Anzeige, **nicht** für `numeric_state` |
| `sensor.radon_meter_radon` | Zahl (Keller) | Radon-Alarm + Lüftungslogik |

## Bekannt / extern (nicht im Repo fixbar)

| Meldung | Quelle | Empfehlung |
|---------|--------|------------|
| `gardena_smart_system` — `async_create_task` from wrong thread | Custom Component | HACS-Update / Issue beim Maintainer; Geräte teils disabled |
| `xiaomi_miot` — Unable to discover Luftbefeuchter | LAN/Cloud Geräte 192.168.188.137/139 | Gerät online? Integration-Update; ggf. IP/Token prüfen (UI) |
| `ESPHome` — Can't connect respeaker-xvf3800-assistant | ESP offline @ 192.168.188.161 | ESP flashen/Netzwerk prüfen |
| `Lovelace is running in storage mode. Define resources via user interface` | `lovelace.mode: storage` + YAML-Ressourcen | Harmlos wenn Dashboards laden; Ressourcen sind in YAML registriert |
| MQTT `object_id` deprecated (Gasmeter/Wasserzähler) | AI-on-the-Edge Discovery | Externes Projekt-Update abwarten |
| `easycontrols` Timeout | Helios-Integration | Bekannt, meist harmlos |
| Custom integration not tested by HA | Alle HACS-Integrationen | Standard-Hinweis beim Start |

## Logger

Aktuell: `logger.default: info` in [`configuration.yaml`](../configuration.yaml). Keine Integration gezielt auf `error` reduziert — bewusst, damit echte Probleme sichtbar bleiben.

## Prüfung

```bash
ha core logs -n 2000 | grep -iE "ERROR|WARNING|Template loop|Radon Alarm"
```

Nach YAML-Änderungen: **Template-Entitäten neu laden** oder Core-Neustart, dann Log erneut prüfen.
