# Dashboard: Garten (Bewässerung & Bodenfeuchte)

Eigenes Lovelace-Dashboard für **8× Froggit-Bodenfeuchte**, **Bewässerungsventile** und Automatik — mit **Pflanzenbildern**.

YAML: [`dashboards/garten.yaml`](../dashboards/garten.yaml) · `url_path`: `/dashboard-garten` · Sidebar: **Garten**

Spec Bewässerung: [`garten-bewaesserung.md`](./garten-bewaesserung.md)

## Zweck

- Alle **CH1–CH8** Feuchtesensoren auf einen Blick (Bild + % + Farbe)
- **Bewässerung** manuell (Tap → Skript) und Automatik-Schalter
- Ergänzt den kompakten Block auf [`dashboard-uebersicht.md`](./dashboard-uebersicht.md) — dort bleibt Kurzüberblick

## Layout (eine View)

1. **Gateway** — Innen-Temp/Feuchte am DP1500 (`sensor.gw1100a_indoor_*`)
2. **Topfpflanzen** — CH1–CH4, CH8 (2× Adrian nebeneinander)
3. **Garten** — CH5 Beet, CH6 Hecke, CH7 Himbeeren (mit Schwellwert Hecke/Beet)
4. **Bewässerung** — 3 Ventile, Rasen/Tropf-Auto, Helfer (Dauer, Schwellwerte, Sperrzeit)

## Pflanzenbilder

Pfad: **`/config/www/images/garden/plants/`** → in HA: `/local/images/garden/plants/…`

| Datei | Kanal | Pflanze | Hinweis |
|-------|-------|---------|---------|
| `gluecksfeder.jpg` | CH1 + CH4 | Glücksfeder | Platzhalter — durch eigenes Foto ersetzen |
| `elefantenfuss.jpg` | CH2 | Elefantenfuß | aus Bestand `plants/yucca elephantipes.jpg` |
| `strahlenaralie.jpg` | CH3 | Strahlenaralie | Platzhalter Schefflera |
| `gluecksbambus.jpg` | CH8 | Glücksbambus | aus Bestand `plants/dracaena braunii.jpg` |
| `beet.jpg` | CH5 | Beet | Platzhalter — eigenes Foto empfohlen |
| `hecke.jpg` | CH6 | Hecke | Platzhalter |
| `himbeeren.jpg` | CH7 | Himbeeren | Platzhalter |

**Eigene Fotos:** JPG/WebP, ca. 400×400 px, Dateiname beibehalten → Dashboard aktualisiert sich ohne YAML-Änderung.

## Farblogik Feuchte

| Bereich | Orange (trocken) | Grün (ok) |
|---------|------------------|-----------|
| Garten Beet/Hecke | unter `input_number.garten_schwellwert_*` | darüber |
| Topfpflanzen | unter **35 %** | ≥ 35 % (Orientierung, kein Helper) |

## Abhängigkeiten

- HACS: **Mushroom**, **card-mod**
- Entities: siehe Kanal-Tabelle in [`garten-bewaesserung.md`](./garten-bewaesserung.md)
- Skripte: `script.garten_*_bewaessern`, `script.garten_bewaesserung_aus`

## Abnahme

- [ ] Sidebar **Garten** öffnet Dashboard
- [ ] Alle 8 Feuchte-Karten zeigen Werte (nicht „Sensor nicht verfügbar“)
- [ ] Bilder sichtbar (sonst Platzhalter-Dateien prüfen)
- [ ] Ventil-Tap startet Bestätigung + Skript
- [ ] Eigene Pflanzenfotos optional nach `/config/www/images/garden/plants/` kopieren
