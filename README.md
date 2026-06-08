# 🏡 Home Automation: Das gesunde Haus

Dieses Repository enthält die vollständige Konfiguration und das Design meines Smart Homes. Die Dokumentation dient als Master-Spezifikation ("Design as Code"), aus der die technische Implementierung abgeleitet wird.

## 🎯 Vision & Prinzipien
Das Ziel ist ein sinnvolles SmartHome. Technik soll den Bewohnern dienen und sich dezent im Hintergrund halten.
- **UI-Standard:** Mushroom Cards mit der "Glue-Method" (nahtlose Integration).
- **Logik-Standard:** Modulare Automationen, getrennt nach Funktionsbereichen.
- **Konfiguration:** Logik, Helfer und Dashboards in **YAML (Git)**; Geräte-Pairing und Konten in der **HA-UI** — siehe [Konfigurations-Strategie](./docs/konfigurations-strategie.md).

## 📚 Dokumentation (Das Design)
Detaillierte Spezifikationen und Anleitungen befinden sich im Ordner `/docs`:
- [**Konfigurations-Strategie**](./docs/konfigurations-strategie.md) – Was in YAML/Git liegt vs. was in der UI bleibt (inkl. Migrations-Backlog).
- [**Dashboard Tablett (EG)**](./docs/dashboard-tablett.md) – Kiosk-Tablet: Touch-UI, Design-Prinzipien, Backlog.
- [**Dashboard Übersicht**](./docs/dashboard-uebersicht.md) – Haupt-Dashboard: Lüftung, Klima, Haushalt, Backlog.
- [**Haushalt: Waschmaschine**](./docs/haushalt-waschmaschine.md) – Leistungs-Schwellen, Neustart-Logik, Push bei fertig.
- [**Haushalt: Trockner**](./docs/haushalt-trockner.md) – wie Waschmaschine, Fertig 3 Min / <6 W.
- [Abgleich-Checkliste](./docs/abgleich-checkliste.md) – Was wir bei Änderungen prüfen, damit Repo und HA konsistent bleiben.
- [**Haus-Warnungen**](./docs/haus-warnungen.md) – Zentrales Monitoring (Tablett + Push), erweiterbar über `group.haus_warnungen_checks`.
- [Integrationen & Add-ons](./docs/integrationen-und-addons.md) – Welche Integrationen/Add-ons im Einsatz sind und wie sie grob konfiguriert werden.
- [Räume & Bereiche](./docs/raeume-und-bereiche.md) – Aktuelle Areas aus Home Assistant als lesbare Referenz.
- [Standards & UI](./docs/standards.md) – Glue-Method, Naming Conventions, KI-Regeln.
- [Beleuchtung](./docs/lights.md) – Szenen, Gruppen, Controller, Inventar.
- [Klima & Umwelt](./docs/climate.md) – Radon-Lüftung, Luftfeuchtigkeit (Platzhalter).
- [Hardware-Inventar](./docs/hardware.md) – Liste aller verbauten Komponenten.
- [Wallboxen](./docs/wallboxes.md) – Wallbox-Notizen.

## 🚀 Aktive Roadmap (To-Do)
*Diese Liste wird bei jeder Änderung aktualisiert und dient der KI als Aufgabenliste:*

- [ ] Briefkastensensor integrieren (Benachrichtigung & Reset-Logik).
- [ ] Mülltonnen-Erinnerung finalisieren.
- [ ] Humidity-Modus für die Lüftungsanlage (Radon-Logik erweitern).
- [ ] Kiosk-Mode für das Tablet (Default Dashboard Layout).
- [ ] Terrasse: Rolladen-Steuerung bei Hitze automatisieren.

## 🛠 Arbeiten mit der KI
Bevor Code-Änderungen (`.yaml`) vorgenommen werden, muss immer zuerst das entsprechende Design-Dokument in `/docs` angelegt, geprüft oder aktualisiert werden. Code ohne Dokumentations-Update gilt als technischer Fehler.

## Cursor Skills & Rules (damit du sie merkst)

### Projekt-Rules (liegen in `.cursor/rules/`)
- `collaboration.mdc` (Docs-first Workflow, Sprache, Scope, Nicht anfassen)
- `home-assistant-yaml.mdc` (Hinweise beim Ändern von `**/*.yaml`)
- `home-assistant-docs.mdc` (Struktur von Feature-Specs in `docs/`)
- `abgleich-checkliste.mdc` (Erinnerung an die Abgleich-Checks)

### Projekt-Skill (liegt in `.cursor/skills/ha-abgleich/`)
- Skill-Datei: `.cursor/skills/ha-abgleich/SKILL.md`
- Name: `ha-abgleich`
- Zweck: systematischer Abgleich Repo ↔ Home Assistant inkl. Doku- und Inventar-Sync