# Sprachsteuerung — Licht Erdgeschoss

Steuerung per **Google Assistant** (Nabu Casa / Home Assistant Cloud) und optional **Assist**.

## Ziel-Phrasen (Beispiele)

| Nutzer sagt (DE) | Wirkung |
|------------------|---------|
| „**Alle Lichter aus**“ / „Licht überall aus“ | ganzes Haus aus (Script) |
| „Alle Lichter im Erdgeschoss aus“ | `light.alle_lichter_erdgeschoss` aus |
| „Alle Lichter Wohnzimmer aus“ | `light.alle_lichter_wohnzimmer` aus |
| „Alle Lichter Esszimmer aus“ | `light.alle_lichter_esszimmer` aus |
| „Licht Küche aus“ / „Küchenlicht aus“ | `light.licht_eg_kueche` aus |

Entsprechend **an** mit „… an“ / „… einschalten“.

## Technik

### Primär: Lichtgruppen (Google = Licht-Gerät)

| Entity | Anzeigename (friendly_name) | Raum-Hinweis Google |
|--------|----------------------------|---------------------|
| `light.alle_lichter_erdgeschoss` | Alle Lichter Erdgeschoss | Raum: **Erdgeschoss** (in HA-UI gesetzt) |
| `light.alle_lichter_wohnzimmer` | Alle Lichter Wohnzimmer | Raum: **Wohnzimmer (EG)** |
| `light.alle_lichter_esszimmer` | Alle Lichter Esszimmer | Raum: **Esszimmer (EG)** |
| `light.licht_eg_kueche` | Licht Küche | Raum: **Küche (EG)** |

Friendly Names in `configuration.yaml` → `homeassistant.customize`.

### Backup: Scripts (Google = „Starte …“)

| Script | Alias | Aktion |
|--------|-------|--------|
| `script.licht_aus_alle` | Alle Lichter aus | EG + David + Adrian + Schlafzimmer aus, `aktive_szene_eg` → — |
| `script.licht_aus_erdgeschoss` | Licht aus Erdgeschoss | EG-Gruppe aus |
| `script.licht_aus_wohnzimmer` | Licht aus Wohnzimmer | Wohn-Gruppe aus |
| `script.licht_aus_esszimmer` | Licht aus Esszimmer | Ess-Gruppe aus |
| `script.licht_aus_kueche` | Licht aus Küche | Küche aus |
| `script.licht_ein_kueche` | Licht Küche an | Neutralwert (`licht_eg_raum_ein`) |
| `script.licht_ein_esszimmer` | Licht Esszimmer an | Neutralwert Ess |
| `script.licht_ein_wohnzimmer` | Licht Wohnzimmer an | Neutralwert Wohn |

### Szenen (Google = „Starte …“ oder Szene direkt)

**EG-Szenen:** über Scripts → setzen zusätzlich `input_select.aktive_szene_eg` (wie 8-fach-Schalter).  
**Direkt** `scene.*` aktivieren geht auch, merkt sich die Szene dann aber nicht für Raum-Schalter.

| Script | Alias | Szene |
|--------|-------|-------|
| `script.szene_eg_hell` | Szene Hell | `scene.hell` |
| `script.szene_eg_gemutlich` | Szene Gemütlich | `scene.gemutlich` |
| `script.szene_eg_brettspiele` | Szene Brettspiele | `scene.brettspiele` |
| `script.szene_eg_kathi_gemutlich` | Szene Kathi Gemütlich | `scene.kathi_gemutlich` |
| `script.szene_eg_kino` | Szene Kino | `scene.kino` |
| `script.szene_eg_sonnenuntergang` | Szene Sonnenuntergang | `scene.sonnenuntergang` |
| `script.szene_eg_kathi_ess` | Szene Kathi Ess | `scene.kathi_ess` |
| `script.szene_david_hell` | Szene David Hell | `scene.david_hell` |
| `script.szene_david_gemutlich` | Szene David Gemütlich | `scene.david_gemutlich` |
| `script.szene_adrian_hell` | Szene Adrian Hell | `scene.adrian_hell` |
| `script.szene_adrian_gemutlich` | Szene Adrian Gemütlich | `scene.adrian_gemutlich` |

Die **Scene-Entities** (`scene.gemutlich`, …) sind in HA bereits für Google freigegeben. Alternativ ohne Scripts:

| Nutzer sagt (DE) | Entity |
|------------------|--------|
| „Schalte Gemütlich ein“ / „Aktiviere Szene Hell“ | `scene.gemutlich`, `scene.hell`, … |

Beispiel-Phrasen mit **Scripts** (empfohlen EG):

- „Hey Google, **starte Szene Gemütlich**“
- „Hey Google, **starte Szene Brettspiele**“
- „Hey Google, **starte Szene Adrian Hell**“

## Freigabe (Git, nicht UI)

Liste: [`google_assistant_expose.yaml`](../google_assistant_expose.yaml) — eingebunden als `cloud.google_actions.filter.include_entities`.  
Enthält nur Entities aus der live Registry (keine historischen `light.0x…`- oder Hue-Raum-Szenen-IDs).  
Nach Änderung: Core-Neustart + „Hey Google, synchronisiere meine Geräte“.

## Einrichtung in Home Assistant (UI, einmalig)

1. **YAML laden:** Skripte neu laden (Entwicklerwerkzeuge → YAML).
2. **Freigabe prüfen:** Einstellungen → **Sprachassistenten** → **Google Assistant** → Tab **Freilegen** (Liste aus YAML, UI ausgegraut)
   - Lichtgruppen + Küchenlicht + Licht-Scripts (s.o.)
   - **Szene-Scripts** (Tabelle oben) — empfohlen für EG
   - Optional: `scene.*` direkt (in expose-Liste)
   - Assist: dieselben Entities optional mitfreigeben
3. **Google Home:** App → Geräte synchronisieren (HA Cloud neu verknüpfen falls nötig).
4. **Optional — Räume:** Einstellungen → Bereiche → Entity dem passenden Bereich zuordnen → bessere Raum-Phrasen („im Wohnzimmer“).

Aliases pro Entity (z. B. „Küchenlicht“) können in der Entity-UI ergänzt werden — bleibt in `.storage`, nicht in Git.

## Grenzen

- Google versteht Formulierungen nicht immer 1:1; Anzeigename und Raum-Zuordnung helfen.
- Scripts heißen in Google oft „Starte Licht aus Küche“ statt natürlichem Toggle.
- **`licht_aus_alle`:** EG-Gruppe + `licht_1og_david`, `licht_1og_adrian`, `licht_2og_schlafzimmer` (siehe [`lights.md`](lights.md)).
- Raum-Scripts (EG) und Szenen: siehe Tabellen oben; 1.OG nur über `licht_aus_alle` oder Einzellampen.

## Referenzen

- Lichtgruppen: [`lights.md`](lights.md)
- EG-Logik Neutralwert: [`licht-eg-anforderungen.md`](licht-eg-anforderungen.md)
