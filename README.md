# 🏡 Home Automation: Das gesunde Haus

Dieses Repository enthält die vollständige Konfiguration und das Design meines Smart Homes. Die Dokumentation dient als Master-Spezifikation ("Design as Code"), aus der die technische Implementierung abgeleitet wird.

## 🎯 Vision & Prinzipien
Das Ziel ist ein sinnvolles SmartHome. Technik soll den Bewohnern dienen und sich dezent im Hintergrund halten.
- **UI-Standard:** Mushroom Cards mit der "Glue-Method" (nahtlose Integration).
- **Logik-Standard:** Modulare Automationen, getrennt nach Funktionsbereichen.

## 📚 Dokumentation (Das Design)
Detaillierte Spezifikationen und Anleitungen befinden sich im Ordner `/docs`:
- [Standards & UI](./docs/standards.md) – Glue-Method, Naming Conventions, KI-Regeln.
- [Beleuchtung](./docs/lighting.md) – Szenen, adaptive Steuerung und Logik.
- [Klima & Umwelt](./docs/climate.md) – Radon-Lüftung, Luftfeuchtigkeit.
- [Haushaltsgeräte](./docs/appliances.md) – Waschmaschine, Trockner, Roborock.
- [Hardware-Inventar](./docs/hardware.md) – Liste aller verbauten Komponenten.

## 🚀 Aktive Roadmap (To-Do)
*Diese Liste wird bei jeder Änderung aktualisiert und dient der KI als Aufgabenliste:*

- [ ] Briefkastensensor integrieren (Benachrichtigung & Reset-Logik).
- [ ] Mülltonnen-Erinnerung finalisieren.
- [ ] Humidity-Modus für die Lüftungsanlage (Radon-Logik erweitern).
- [ ] Kiosk-Mode für das Tablet (Default Dashboard Layout).
- [ ] Terrasse: Rolladen-Steuerung bei Hitze automatisieren.

## 🛠 Arbeiten mit der KI
Bevor Code-Änderungen (`.yaml`) vorgenommen werden, muss immer zuerst das entsprechende Design-Dokument in `/docs` angelegt, geprüft oder aktualisiert werden. Code ohne Dokumentations-Update gilt als technischer Fehler.