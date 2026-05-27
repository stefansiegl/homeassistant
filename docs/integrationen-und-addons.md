# Integrationen & Add-ons (Setup-Notizen)

Dieses Dokument beschreibt, **welche Integrationen, Add-ons und HACS-Frontends** im Projekt „Das gesunde Haus“ verwendet werden und welche wichtigen Einstellungen bei einer Neuinstallation / Neuverknüpfung zu beachten sind.

Es ist eine Ergänzung zur [`konfigurations-strategie.md`](./konfigurations-strategie.md): Dort steht, **ob** etwas in YAML oder UI lebt – hier steht, **wie** wir es typischerweise konfigurieren.

---

## Grundprinzip

- **Logik & Darstellung** (Automationen, Szenen, Dashboards, Helfer) → siehe `konfigurations-strategie.md` und die jeweiligen Feature-Specs.
- **Integrationen & Add-ons** (MariaDB, MQTT, Zigbee2MQTT, ESPHome, Music Assistant, MS365, …) werden in der Regel:
  - über die **UI installiert/verbunden** (Konten, Tokens, Pairing),
  - aber hier mit den wichtigsten **Optionen, Stolpersteinen und benötigten Secrets** dokumentiert.

Dieses Dokument ist ausdrücklich **für dich** gedacht (und nicht für die KI als alleinige Quelle der Wahrheit).

---

## Add-ons (Supervisor)

> Liste der Add-ons, die für das System relevant sind. Für jedes Add-on: Zweck, wo es konfiguriert wird, und welche Secrets in YAML referenziert werden.

### Aktuelle Add-ons (Stand: manuell aus HA „Apps“ Liste)

Hinweis: „Update verfügbar“/„gestoppt“ ist eine Momentaufnahme. Für die operative Wartung zählt der aktuelle Zustand in Home Assistant.

- **ESPHome Device Builder** (Update verfügbar)
  - Zweck: ESPHome-Geräte bauen/flashen (z. B. Bluetooth-Proxies, ReSpeaker).
  - Konfiguration: Build/Logs über Add-on-UI; Geräte-Definitionen liegen in `esphome/*.yaml`.

- **File editor** (gestoppt)
  - Zweck: Browserbasierter Editor für `/config`.
  - Hinweis: Optional, da wir ohnehin mit Cursor/VSCode arbeiten. Nur starten, wenn du schnell in HA selbst editieren willst.

- **Get HACS** (läuft)
  - Zweck: HACS Bootstrap / Installer.
  - Hinweis: Wenn HACS sauber installiert ist, wird dieses Add-on oft nicht mehr aktiv benötigt.

- **Grafana** (Update verfügbar)
  - Zweck: Dashboards/Visualisierung, meist mit InfluxDB.

- **Grocy** (läuft, aber nicht mehr genutzt)
  - Status: **deprecated bei uns**.
  - TODO: Optional deaktivieren/entfernen, wenn du sicher bist, dass keine Daten/Automationen mehr daran hängen.

- **Home Assistant Google Drive Backup** (läuft)
  - Zweck: Backups nach Google Drive.
  - Hinweis: Ergänzt die „Snapshot vor großen Änderungen“-Regel.

- **InfluxDB** (Update verfügbar)
  - Zweck: Zeitreihen-Datenbank für Metriken (z. B. für Grafana).
  - YAML-Anker: In `configuration.yaml` existiert bereits `influxdb:`-Konfiguration (Host/DB/User/Secret).

- **MariaDB / Datenbank**
  - Zweck: Recorder-Backend für Historie.
  - Konfiguration:
    - Add-on-UI (Benutzer/Passwort/DB-Name).
    - In `configuration.yaml` unter `recorder:` → `db_url: !secret maria_db_recorder_db_url`.
  - Wichtig: Nach Passwort-/Host-Änderung sowohl Secret als auch Add-on-Config anpassen.

- **Mosquitto MQTT**
  - Zweck: MQTT-Broker für Zigbee2MQTT, AI-on-the-Edge, etc.
  - Konfiguration:
    - Add-on-UI (Benutzer `zigbee2mqtt`, Passwörter).
    - In Zigbee2MQTT (`zigbee2mqtt/configuration.yaml`) `mqtt:`-Block anpassen (Server, User, Passwort über Secret empfehlenswert).

- **Rclone Backup** (läuft)
  - Zweck: Backups zusätzlich zu Remote-Targets via rclone synchronisieren.
  - Hinweis: Kann parallel zu Google Drive Backup laufen.

- **Samba share** (läuft)
  - Zweck: Zugriff auf `/config` per SMB.
  - Hinweis: Praktisch für lokale Geräte; Zugriff/Passwörter sind Infrastruktur-Thema.

- **Studio Code Server** (läuft)
  - Zweck: VSCode im HA-Frontend.
  - Hinweis: Optional, wenn du lieber direkt in HA editierst; Cursor kann das ersetzen.

- **Terminal & SSH** (Update verfügbar)  ✅ wichtig für Cursor
  - Zweck: SSH-Zugang (u. a. für Cursor-Verbindung / Remote-Editing).
  - Wichtig:
    - **Darf nicht fehlen**, sonst verlieren wir den Remote-Zugriff.
    - Updates vorsichtig: erst Snapshot, dann Update, danach SSH-Verbindung testen.

- **Zigbee2MQTT**
  - Zweck: Zigbee-Netz, Hue-Schalter, Steckdosen, Sensoren.
  - Konfiguration:
    - Hardware/Port: in Add-on-UI.
    - Logik & Geräte-Namen: in `zigbee2mqtt/configuration.yaml`.
  - Wichtig:
    - `friendly_name` ist die wichtigste Brücke zur Doku (`docs/lights.md`).
    - `channel`, `network_key`, `pan_id` **nicht** leichtfertig ändern.

- **ESPHome**
  - Zweck: Bluetooth-Proxies, ReSpeaker, weitere ESP-Geräte.
  - Konfiguration:
    - Geräte-YAML in `esphome/*.yaml` (im Repo).
    - Flashen / Logs über Add-on-UI.
  - Secrets:
    - WLAN- und API-Passwörter in `esphome/secrets.yaml` (nicht in Git).

- **Music Assistant**
  - Zweck: Zentrale Jukebox / Multiroom-Audio.
  - Notizen:
    - Läuft als Add-on; Konfiguration von Providern (Spotify-Konten, Sonos, Google Cast) in der MA-Weboberfläche.
    - Strategie: mehrere Spotify-Konten (Papa, Adrian, David) für parallele Nutzung.
    - Podcasts: ARD/Audiothek lieber über dedizierten Provider als über Spotify abspielen.
  - Status: aktuell **gestoppt** (laut Apps-Liste) → bei Bedarf wieder starten.

*(Weitere Add-ons wie AI-on-the-Edge, ggf. InfluxDB etc. können wir ergänzen, wenn wir sie aktiv anfassen.)*

---

## Wichtige Integrationen (UI + YAML-Anker)

> Hier geht es um Integrationen unter „Einstellungen → Geräte & Dienste“, bei denen zusätzlich YAML-Anteile existieren.

- **Waste Collection Schedule (Awido)**
  - Einrichtung:
    - Integration via UI / HACS (falls nötig).
    - YAML-Block in `configuration.yaml` unter `waste_collection_schedule:` (bereits vorhanden).
  - Secrets:
    - `waste_collection_customer`, `waste_collection_city`, `waste_collection_street` in `secrets.yaml`.
  - Logik:
    - Templates für `_days` und `_display` unter `template:` in `configuration.yaml`.
    - Dashboard-Visualisierung siehe Google-Doc-Archiv bzw. spätere Spec.

- **Powercalc**
  - Zweck: Automatische Leistung-/Energie-Sensoren für Lichter etc.
  - Konfiguration:
    - YAML-Block in `configuration.yaml` unter `powercalc:` (global).
    - Geräte-spezifische Profile teils in `.storage/powercalc_profiles/` (nicht in Git).

- **Viessmann / ViCare**
  - Zweck: Heizung / Klima.
  - Einrichtung:
    - Integration via UI (OAuth gegen Viessmann).
  - Wichtige Entitäten:
    - `climate.e3_vitovalor_pt2_0419` etc. (siehe Google-Doc-Hardware-Inventar).

- **Electricity Maps**
  - Zweck: CO₂-Intensität des Stromnetzes.
  - Einrichtung:
    - Integration via UI, API-Key im Secret.

- **MS365 / Microsoft To Do**
  - Zweck: Einkaufslisten & Aufgaben in MS To Do.
  - Einrichtung (stark komprimiert):
    - App-Registrierung in Azure (Client-ID, Secret, Redirect-URI `https://login.microsoftonline.com/common/oauth2/nativeclient`).
    - Integration in HA via HACS „MS365“, ohne „alternate authentication“.
    - **Wichtig:** „Returned URL“ aus der Fehlerseite vollständig kopieren und im HA-Dialog einfügen.
    - In der Konfiguration `Update Service` aktivieren, sonst bleiben Listen read-only.
  - Sprachassistent:
    - Relevante To-Do-Listen in `Einstellungen → Sprachassistenten → Freilegen` freigeben.

- **AI-on-the-Edge (Gas & Wasser)**
  - Zweck: Auslesen analoger Zähler per ESP32-CAM + MQTT.
  - Spec: [`ai-on-the-edge.md`](./ai-on-the-edge.md) — Entities, Live-Status, Energie-Dashboard, Fehler-Handling.
  - Einrichtung: Geräte-Web-UI + Mosquitto; HA MQTT-Integration (Auto-Discovery). YAML: `customize`, Template `sensor.watermeter_in_l`, Recorder-Filter in `configuration.yaml`.

*(Weitere Integrationen wie Xiaomi Miot Auto für Staubsauger etc. können wir ergänzen, sobald wir sie aktiv anfassen.)*

---

## Frontend / HACS-Frontend-Komponenten

> Dinge, die das Dashboard aussehen lassen wie “Das gesunde Haus”.

- **Mushroom Cards & Mushroom Theme**
  - Installation:
    - Über HACS (Frontend).
  - Nutzung:
    - Mushroom-Karten überall im Dashboard.
    - Theme-Auswahl in Profil / Einstellungen.
  - Details zur Glue-Method & Layout:
    - siehe `docs/standards.md` und ggf. konkrete Dashboard-Specs.

- **card-mod**
  - Zweck: CSS-Anpassungen, Glue-Method (Rahmen weg, Gruppen optisch verbinden).
  - Konfiguration:
    - Ressource über UI oder später YAML, abhängig vom Lovelace-Modus (noch Storage).

---

## Wie wir dieses Dokument nutzen

- **Beim Neuaufsetzen** (anderer Host, Neuinstallation):
  - Reihenfolge grob: Add-ons → Integrationen → YAML-Dateien aus diesem Repo.
  - Dieses Dokument hilft, UI-Schritte und Secrets nicht zu vergessen.
- **Beim Erweitern** (neue Integration):
  - Kurze Notiz hier ergänzen: Was wurde installiert, welche Secrets, welche kritischen Optionen?
- **Für die KI:**
  - Dieses Dokument ist ein **Hint**, nicht die alleinige Wahrheit. Bei Widerspruch zählen `konfigurations-strategie.md`, `standards.md` und die reale Konfiguration.

