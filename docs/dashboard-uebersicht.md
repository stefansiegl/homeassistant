# Dashboard: Übersicht (Haupt-Dashboard)

Kiosk-freundliche **Steuerzentrale** für das Haus (`url_path`: `/lovelace`, Sidebar: **Übersicht**).

YAML: [`dashboards/uebersicht.yaml`](../dashboards/uebersicht.yaml) — 1:1 aus `.storage/lovelace.lovelace` migriert.

## Zweck

Zentrales Dashboard für Lüftung, Raumklima, Haushalt, Müll und Wartung. Mushroom + card-mod (Glue-Method), eine View „Home“.

## Inhalts-Blöcke (Reihenfolge)

1. **Lüftungszentrale** — Helios-Stufe, Max-CO₂, Effizienz, Sommer/Winter-Bypass, Kill-Switch
2. **Raumklima** — 4 Zeilen: EG Küche, 1. OG, 2. OG Büro, 2. OG Schlafen (Temp, Feuchte, CO₂, Befeuchter, Wasser leer)
3. **Haushalt** — Waschmaschine, Trockner, Spülmaschine (Status-Helper + Leistung)
4. **Radon Debug** — `sensor.radon_meter_radon` (entities-Karte)
5. **Radon Logik** — `input_boolean.radon_logic_enabled`
6. **Abfallentsorgung** — Übersicht + 4 Müll-Sensoren
7. **Zigbee2MQTT** — `switch.zigbee2mqtt_bridge_permit_join`
8. **Haus-Wartung** — Befeuchter-Reinigung, Lüfterfilter (Tap setzt Datum mit Bestätigung)

## Abhängigkeiten

- HACS: **Mushroom**, **card-mod** (18× `card_mod.style`)
- Ressourcen derzeit noch in `.storage/lovelace_resources` (globaler Backlog: in YAML)

## Entity-Audit (Stand Migration)

Referenzierte Entities (Auszug): Helios, Aranet/ESPHome-Räume, Deerma-Befeuchter, Waste-Sensoren, Haushalt-Helper, Wartungs-`input_datetime`/`input_number`.

**Bekannte Defekte im Dashboard (1:1 übernommen, Backlog):**

| Referenz | Problem |
|----------|---------|
| `sensor.spuelmaschine_leistung` | Entity existiert nicht — Leistung in Spülmaschinen-Karte fehlt |
| `sensor.shellyplug_s4_trockner_power` | Falscher Name — Registry: `sensor.shellyplug_4_trockner_power` |

## Backlog (inhaltlich)

- [ ] **Radon + Lüftung** — Debug-Karten (Block 4/5) und Automatisierung gemeinsam prüfen; Radon-hohe Lüfterstufe bringt vermutlich nicht den gewünschten Effekt
- [ ] Spülmaschinen-Leistungssensor korrekt anbinden
- [ ] Trockner power entity_id korrigieren
- [ ] Lovelace-Ressourcen dauerhaft in `configuration.yaml` (siehe Strategie-Doc)
- [ ] Layout/Inhalt später verfeinern (nicht Teil der Migration)

## Migration

- Quelle: `.storage/lovelace.lovelace`
- Registrierung: `lovelace:` unter `configuration.yaml` → `dashboards/lovelace`
- **Core-Neustart** nötig (nicht nur YAML reload)
- Storage-Metadaten können in `.storage` liegen bleiben (harmlos, wie bei Adrian Licht / Tablett)

## Siehe auch

- [`konfigurations-strategie.md`](./konfigurations-strategie.md)
- [`dashboard-tablett.md`](./dashboard-tablett.md) — EG-Tablet (anderer Use-Case)
- [`climate.md`](./climate.md) — Lüftung/Radon (Platzhalter)
