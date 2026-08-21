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
- [**Dashboard Lüftung**](./docs/dashboard-luftung.md) – CO₂/Temperatur/Lüfter-Verlauf zur Wirkungskontrolle.
- [**Haushalt: Waschmaschine**](./docs/haushalt-waschmaschine.md) – Leistungs-Schwellen, Neustart-Logik, Push bei fertig.
- [**Haushalt: Trockner**](./docs/haushalt-trockner.md) – wie Waschmaschine, Fertig 3 Min / <6 W.
- [Abgleich-Checkliste](./docs/abgleich-checkliste.md) – Was wir bei Änderungen prüfen, damit Repo und HA konsistent bleiben.
- [**Live-Audit**](./docs/live-audit.md) – Periodischer Repo↔Live-Abgleich (modular, `/loop`-fähig).
- [**Haus-Warnungen**](./docs/haus-warnungen.md) – Zentrales Monitoring (Tablett + Push), erweiterbar über Check-Entity-Liste in `sensor.haus_warnungen`.
- [Integrationen & Add-ons](./docs/integrationen-und-addons.md) – Welche Integrationen/Add-ons im Einsatz sind und wie sie grob konfiguriert werden.
- [**Garten-Bewässerung**](./docs/garten-bewaesserung.md) – Zigbee-Bodenfeuchte, Gardena BT-Ventile, Automationen.
- [**Sprachsteuerung Garten**](./docs/sprachsteuerung-garten.md) – Google Assistant: Rasensprenger, Versenkregner/Kreisregner, Tropf, Status.
- [**Sprachsteuerung Licht EG**](./docs/sprachsteuerung-licht-eg.md) – Google Assistant: Lichtgruppen, Szenen, Aliase.
- [**Backup-Strategie**](./docs/backup-strategie.md) – GitHub, Google Drive, Verschlüsselung, was nicht in Git liegt.
- [Räume & Bereiche](./docs/raeume-und-bereiche.md) – Aktuelle Areas aus Home Assistant als lesbare Referenz.
- [Standards & UI](./docs/standards.md) – Glue-Method, Naming Conventions, KI-Regeln.
- [Beleuchtung](./docs/lights.md) – Szenen, Gruppen, Controller, Inventar.
- [Klima & Umwelt](./docs/climate.md) – Lüftung (CO₂, Nacht-Kühlung, Status-Sensor).
- [Hardware-Inventar](./docs/hardware.md) – Liste aller verbauten Komponenten.
- [Wallboxen](./docs/wallboxes.md) – Wallbox-Notizen.

## 🚀 Aktive Roadmap (To-Do)
*Diese Liste wird bei jeder Änderung aktualisiert und dient der KI als Aufgabenliste:*

- [ ] Briefkastensensor integrieren (Benachrichtigung & Reset-Logik).
- [ ] Mülltonnen-Erinnerung finalisieren.
- [ ] Humidity-Modus für die Lüftungsanlage (Radon-Logik erweitern).
- [ ] Kiosk-Mode für das Tablet (Default Dashboard Layout).
- [ ] Terrasse: Rolladen-Steuerung bei Hitze automatisieren.
- [ ] **Waschmaschine Home Connect neu verbinden** — Integration eingerichtet (22.06.), liefert keine Live-Daten (`Konnektivität` dauerhaft `off`); Shelly-Logik läuft weiter. Siehe [`docs/haushalt-waschmaschine.md`](./docs/haushalt-waschmaschine.md#offen-home-connect).

## 📋 Backlog (vorbereitet, später)

- [ ] **Gardena Bluetooth → Home Assistant Core:** Upstream-PR einreichen (Patch fertig: [`docs/upstream-pr-gardena-bluetooth.md`](./docs/upstream-pr-gardena-bluetooth.md), [`upstream-patches/home-assistant-core/`](./upstream-patches/home-assistant-core/)). Bis Merge: Custom Integration `gardena_bluetooth (Proxy Fix)` behalten.

## 🛠 Arbeiten mit der KI
Bevor Code-Änderungen (`.yaml`) vorgenommen werden, muss immer zuerst das entsprechende Design-Dokument in `/docs` angelegt, geprüft oder aktualisiert werden. Code ohne Dokumentations-Update gilt als technischer Fehler.

## Claude Code: Regeln & Skills (damit du sie merkst)

### Projekt-Regeln
- [`CLAUDE.md`](./CLAUDE.md) (Docs-first Workflow, Sprache, Scope, Nicht anfassen, YAML-Standards, Energie-Statistik-Wartung — wird automatisch geladen)

### Projekt-Skills (liegen in `.claude/skills/`)

| Skill | Datei | Zweck |
|-------|-------|-------|
| `ha-abgleich` | `.claude/skills/ha-abgleich/SKILL.md` | Checkliste bei Implementierung / Migration |
| `ha-live-audit` | `.claude/skills/ha-live-audit/SKILL.md` | Periodischer Docs↔Live-Abgleich (`bin/audit-live.sh`, `/loop`) |