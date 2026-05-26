# Archiv: Google-Docs Notizen (unsicherer Stand)

Dieses Dokument ist ein **Archiv** von älteren Notizen aus einem Google Doc.

- **Status:** möglicherweise veraltet / teilweise widersprüchlich
- **Quelle der Wahrheit:** Die aktuellen Markdown-Dokumente in `/docs` (z. B. `standards.md`, `konfigurations-strategie.md`, `lights.md`, `hardware.md`)
- **Regel:** Aus diesem Archiv wird **nichts** direkt implementiert, ohne dass wir es gegen die aktuellen MDs und die reale HA-Installation verifizieren.

---

## Was wir mit dem Google Doc machen

Wir nutzen es als **Ideen-Inbox** und **Historie**:

- **Behalten:** gute Formulierungen, Checklisten, Hardware-HowTos, Design-Prinzipien
- **Überführen:** nur verifizierte Inhalte in passende, “sichere” MDs (siehe unten)
- **Entsorgen/Depriorisieren:** Dinge, die nicht mehr gelten oder inzwischen anders gelöst sind

---

## Wichtige Abweichung (bitte bewusst entscheiden)

Im Google Doc steht teils: **“UI-First … Komponenten primär über die Home Assistant UI anlegen”**.

Unser aktueller Repo-Ansatz ist: **Docs-first** und zunehmend **YAML/Git** für Logik/Helfer/Dashboards (siehe `konfigurations-strategie.md`).

Wenn du UI-First weiterhin willst, können wir das als Strategie festschreiben — dann müssten wir `konfigurations-strategie.md` entsprechend anpassen.

---

## Inbox: To-Dos / Ideen (aus dem Google Doc)

Diese Liste ist **nicht automatisch aktuell**. Sie dient als Sammelstelle.

- Briefkastensensor (inkl. Reset-Logik)
- ggf. gleiches Prinzip für Mülltonnen
- Saugroboter-Integration + “nur saugen wenn Türen offen”
- Humidity-Modus / Sommer-Boost für Lüftung
- Pflanzen/Feuchte ggf. neu bewerten
- Bewässerung: HA vs. Gardena-Timer
- Dashboard-Überblick: Warnungen, Batteriestatus, Updates, Navigation
- Wetterdetails (Nutzen unklar)
- Terrasse Rolladen: Hitze-Automation
- “Sensor liefert keine Werte” Warnungen
- Energie-Dashboard Vollständigkeit prüfen

---

## Inbox: Beleuchtung (HowTo / Notizen)

### Schalter → Taster Umbau (Hue Wall Switch Modul)

Die Schritte aus dem Google Doc scheinen plausibel (Sicherung raus, Feder, device_mode/push_button in Z2M).
**Verifikation:** In `docs/lights.md` und Zigbee2MQTT prüfen, welche Geräte betroffen sind und wie sie aktuell konfiguriert sind.

### Adaptive Lighting

Notiz: HACS-Integration “Adaptive Lighting”, take_over_control aktivieren, Schalter-Automationen über Device Trigger.
**Verifikation:** Ist Adaptive Lighting installiert? Welche Lichter/Gruppen sind dort eingebunden?

### LED-Stripes / Gledopto / COB RGBCCT Einkaufsliste

Das ist Einkaufs-/Hardware-Planung. Gehört in eine eigene Spec, z. B. `docs/lighting-led-stripes.md`, sobald du das Thema aktiv angehst.

---

## Inbox: Prinzipien / Regeln (zum Überführen nach Verifikation)

Folgende Punkte sind *potenziell* wertvoll, aber müssen zu `docs/standards.md` passen:

- Robustheit & Neustart-Sicherheit (homeassistant start trigger, Delay/Guard Clauses, defensive float defaults)
- Template-Sicherheit (`| float(0)` vor `| round(0)`)
- Mushroom/Glue-Method Details (card_mod CSS)
- Notification UX (“Kritische Information zuerst”)
- Unterschied UI-YAML vs Datei-YAML (Bindestrich-Regel)

---

## Migration-Notizen (Dashboards / Automationen)

Im Google Doc stehen große YAML-Blöcke für Dashboards und Automationen.

**Aktueller Stand im Repo:**

- Automationen: `automations.yaml` ist bereits file-based
- Dashboards: liegen aktuell überwiegend in `.storage` (storage mode) → Migration geplant in `konfigurations-strategie.md`

**Vorgehen:** Wir migrieren pro Dashboard/Feature in kleinen Schritten und kopieren dabei nur das, was wir im laufenden HA tatsächlich wiederfinden.

---

## Nächster Schritt (konkret)

Wenn du willst, machen wir das in 20–30 Minuten “aufgeräumt”:

1. Du sagst: welche 2–3 Bereiche aus dem Google Doc sind **sicher noch relevant** (z. B. Lüftung, Waschmaschine/Trockner/Spülmaschine, Warnungs-Dashboard).
2. Ich erstelle dafür je einen kurzen **verifizierbaren** Spec-Entwurf in `/docs` (oder erweitere vorhandene).
3. Erst danach implementieren/migrieren wir YAML.

