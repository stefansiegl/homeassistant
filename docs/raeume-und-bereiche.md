# Räume & Bereiche (Areas) – Stand Home Assistant

Dieses Dokument ist eine **lesbare Kopie** der aktuell in Home Assistant konfigurierten **Bereiche (Areas)**.

- **Quelle:** `/.storage/core.area_registry` (read-only, nicht in Git)
- **Zweck:** Haus-Struktur als Referenz für Specs, Dashboards und Automationen
- **Hinweis:** Area-IDs können “historisch” sein; die **Anzeigenamen** sind entscheidend.

---

## Übersicht (aus `core.area_registry`)

### Keller

- **Heizungsraum (Keller)** (`keller_heizung`)
- **Spielzimmer (Keller)** (`spielzimmer_keller`)
- **Vorratsraum (Keller)** (`vorratsraum_keller`)

### Erdgeschoss (EG)

- **Erdgeschoss** (`erdgeschoss`)
- **Esszimmer (EG)** (`esszimmer`) — Bodenfeuchte Froggit **CH3** (Strahlenaralie)
- **Küche (EG)** (`kuche`)
- **Wohnzimmer (EG)** (`wohnzimmer`) — Bodenfeuchte Froggit **CH2** (Elefantenfuß)
- **Toilette (EG)** (`toilette_eg`)
- **Klo EG** (`klo_eg`)

### 1. Obergeschoss (1.OG)

- **Bad (1.OG)** (`bad_1_og`)
- **Gang (1.OG)** (`gang_1_og`)
- **Legozimmer (1.OG)** (`legozimmer_1_og`)
- **Spielzimmer (1. OG)** (`spielzimmer_1_og`)

### 2. Obergeschoss (2.OG)

- **Arbeitszimmer (2.OG)** (`arbeitszimmer_2_og`)
- **Bad (2. OG)** (`bad`)
- **Gang (2.OG)** (`gang_2_og`)
- **Schlafzimmer (2. OG)** (`schlafzimmer`)

### Außen

- **Balkon** (`balkon`)
- **Garten** (`garten`) — Bodenfeuchte Froggit **CH5** (Beet), **CH6** (Hecke), **CH7** (Himbeeren); Details [`garten-bewaesserung.md`](./garten-bewaesserung.md)
- **briefkasten** (`briefkasten`)

### Personen / Sonstiges

- **Adrian** (`adrian`) — Bodenfeuchte Froggit **CH1** + **CH4** (Glücksfeder klein/groß)
- **david** (`david`) — Bodenfeuchte Froggit **CH8** (Glücksbambus)
- **Bedroom** (`bedroom`)
- **Badezimmer** (`badezimmer`)
- **bad 2og** (`bad_2og`)
- **work** (`work`)
- **AMS** (`ams`)
- **HA-Component** (`ha_component`)
- **Regal** (`regal`)
- **Unknown** (`unknown`)

---

## Aufräum-Kandidaten (Duplikate / Inkonsistenzen)

Diese Einträge wirken doppelt oder inkonsistent (nur Hinweis, keine Änderung am System):

- **Toilette EG**: `Toilette (EG)` vs `Klo EG`
- **Bad 2OG**: `Bad (2. OG)` vs `bad 2og` vs `Badezimmer`
- **Schlafzimmer**: `Schlafzimmer (2. OG)` vs `Bedroom` (englisch)
- **Personen**: `Adrian` vs `david` (Groß/Kleinschreibung)
- **Sammel-/Platzhalter**: `Unknown`, `HA-Component`, `AMS`, `Regal`, `work`

Wenn du willst, können wir dafür eine kleine Spec schreiben (z. B. `docs/areas-aufräumen.md`) und dann in HA sauber umbenennen/zusammenführen.

