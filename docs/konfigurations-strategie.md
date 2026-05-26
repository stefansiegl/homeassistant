# Konfigurations-Strategie: YAML (Git) vs. UI (Home Assistant)

Dieses Dokument legt fest, **was in Dateien im Repository** liegt und **was bewusst in der Home-Assistant-Oberfläche** bleibt. Ziel: Nachvollziehbarkeit in Git, sichere Zusammenarbeit mit der KI, weniger Copy-&-Paste-Chaos.

**Kurzregel:** Alles, was *Verhalten, Logik und Oberfläche* definiert → nach und nach **YAML**. Alles, was *Geräte anbinden, Konten verknüpfen oder einmalig einrichten* → meist **UI**.

---

## Warum die Trennung?

| YAML / Git (`/config`) | UI / `.storage` (nicht in Git) |
|------------------------|--------------------------------|
| Versioniert, diffbar, reviewbar | Schnell für Einmal-Setup |
| KI und Mensch arbeiten am gleichen Stand | Gut für Pairing & Assistenten |
| Wiederherstellung nach Backup klar | Enthält Registry-Zustand, Tokens |

`.storage/` ist in `.gitignore` — was nur dort lebt, ist für das Repo unsichtbar.

**Ablauf:** Spec in `/docs` → Umsetzung in YAML (dieses Dokument) oder Einrichtung in der UI (Pairing, Konten).

---

## In YAML / Konfigurationsdateien (Ziel: hier)

Diese Bereiche gehören ins Repository. Die KI darf sie nach Spec ändern; du testest mit **YAML prüfen** und Reload.

### Kern-Home-Assistant

| Was | Typische Datei | Status bei uns | Hinweise |
|-----|----------------|----------------|----------|
| Zentrale Einstellungen (Recorder, Influx, Logger, …) | `configuration.yaml` | ✅ aktiv | Secrets nur via `!secret` |
| Template-Sensoren, -Schalter, -Buttons | `configuration.yaml` → `template:` | ✅ aktiv | z. B. Müll-Anzeige, Wasserzähler |
| Automationen | `automations.yaml` | ✅ aktiv | Modular nach Bereich halten |
| Szenen | `scenes.yaml` | ✅ aktiv | Vollständige Licht-Parameter dokumentiert |
| Skripte | `scripts.yaml` | ⚠️ prüfen | Datei derzeit leer — UI-Skripte ggf. migrieren |
| Blueprints (wiederverwendbar) | `blueprints/` | ✅ aktiv | Eigene + Community-Blueprints |
| Packages (optional, große Teile) | `packages/*.yaml` | ❌ noch nicht | Sinnvoll, wenn `configuration.yaml` wächst |

### Helfer & Logik-Entitäten

| Was | Typische Datei | Status bei uns | Hinweise |
|-----|----------------|----------------|----------|
| `input_boolean` | `configuration.yaml` oder `helpers.yaml` | 🔄 migrieren | z. B. Lüftungs-Kill-Switch, Radon-Logik |
| `input_number` | wie oben | 🔄 migrieren | z. B. Ziel-Luftfeuchtigkeit, Schwellwerte |
| `input_select` | wie oben | 🔄 migrieren | z. B. Waschmaschinen-Status |
| `input_text` / `input_datetime` | wie oben | 🔄 migrieren | IDs beim Migrieren **beibehalten** |
| `timer`, `counter` | YAML | — | Falls genutzt, ebenfalls in YAML |
| `schedule` | YAML | — | Zeitpläne für Automationen |

### Integrationen mit eigener Config-Datei

| Was | Typische Datei | Status bei uns | Hinweise |
|-----|----------------|----------------|----------|
| Zigbee-Geräte (Namen, Kanäle) | `zigbee2mqtt/configuration.yaml` | ✅ aktiv | friendly_name = Vertrag mit Doku |
| ESPHome-Geräte | `esphome/*.yaml` | ✅ aktiv | `secrets.yaml` nicht committen |
| Waste Collection, Powercalc, … | `configuration.yaml` | ✅ aktiv | Integrations-Block im Core |

### Dashboards (Lovelace)

| Was | Typische Datei | Status bei uns | Hinweise |
|-----|----------------|----------------|----------|
| Dashboard-Layouts | `dashboards/*.yaml` | 🔄 migrieren | Derzeit 8 Dashboards in `.storage` |
| Lovelace-Ressourcen (Mushroom, card-mod) | `configuration.yaml` oder `lovelace/` | 🔄 teilweise | Bis Migration: oft noch in UI |
| Themes | `themes/` | ⚠️ in `.gitignore` | Bewusst aus Git — ggf. später anders |

**Migration Dashboards:** Pro Dashboard ein Schritt — Raw-Editor oder Export aus `.storage` → `dashboards/<name>.yaml` → in `configuration.yaml` unter `lovelace: dashboards:` registrieren → testen → altes Storage-Dashboard entfernen.

### Dokumentation (Design as Code)

| Was | Datei | Hinweise |
|-----|-------|----------|
| Feature-Specs | `docs/<feature>.md` | Vor YAML-Änderung |
| Inventar Lichter / Hardware | `docs/lights.md`, `docs/hardware.md` | Bei neuen Entities aktualisieren |
| Standards, Naming | `docs/standards.md` | |
| Diese Strategie | `docs/konfigurations-strategie.md` | |

### Was wir **nicht** in Git erwarten

| Was | Grund |
|-----|--------|
| `secrets.yaml` (Inhalt) | In `.gitignore` — nur Platzhalter/`!secret` in committeten Dateien |
| `custom_components/` | In `.gitignore` — Updates über HACS, nicht Hand-Patches im Repo |
| `.storage/`, `.cloud/`, Datenbanken, Logs | Laufzeit & Registry |

---

## In der UI lassen (bewusst manuell)

Diese Schritte machst **du in Home Assistant** (oder über Add-on-UIs). Die KI dokumentiert Ergebnisse in `/docs`, ändert aber nicht `.storage` per Hand.

### Geräte & Integrationen

| Was | Wo | Warum UI |
|-----|-----|----------|
| Integration hinzufügen (HACS, MQTT-Broker, Vicare, …) | Einstellungen → Geräte & Dienste | OAuth, Discovery, einmalige Einrichtung |
| Zigbee-Gerät **pairing** | Zigbee2MQTT-Frontend / ZHA | Hardware-Procedure |
| ESPHome **flashen** | ESPHome Add-on / Dashboard | Firmware, nicht nur YAML |
| Bluetooth-Gerät koppeln | HA Bluetooth / ESPHome Proxy | Reichweite, Pairing-Dialog |
| Gerät löschen / ersetzen | Geräte-UI | Registry-Einträge |
| Entity deaktivieren, „Zur Übersicht hinzufügen“ | Entitäten-UI | Feintuning ohne YAML-Zwang |
| Bereiche (Areas) zuweisen | Einstellungen → Bereiche | Kann YAML, bei uns oft UI — in Doku festhalten |
| Labels | UI | Organisation |

### Konten & Cloud

| Was | Wo |
|-----|-----|
| Home Assistant Cloud (Nabu Casa) | UI / `.cloud` |
| Google / Microsoft / Spotify-Login | Integrations-UI |
| Mobile App, Benachrichtigungs-Targets | App + Personen |
| Benutzer & Rechte | Einstellungen → Personen |

### Add-ons & Infrastruktur (HAOS)

| Was | Wo |
|-----|-----|
| Add-ons installieren (MariaDB, Mosquitto, Zigbee2MQTT, ESPHome) | Supervisor |
| Add-on-Optionen (Ports, Passwörter) | Add-on-Konfiguration → ggf. in `secrets` spiegeln |
| Backups / Snapshots | Supervisor |
| Updates Core / OS / Add-ons | Supervisor |

### Sonstiges UI-typisch

| Was | Wo | Anmerkung |
|-----|-----|-----------|
| Energie-Dashboard-Zuordnung | Energie | Entitäten aus YAML/UI, Zuordnung oft UI |
| Map, Karten-Integration | UI | |
| Assist / Sprachassistenten-Phrasen | UI | Logik trotzdem in Automationen (YAML) |
| Reparaturen (Repairs) | UI | |
| Experimentelle Dashboards („test“) | UI bis stabil | Dann nach YAML migrieren |

---

## Grauzone — gemeinsam entscheiden

| Thema | Empfehlung | Bei uns |
|-------|------------|---------|
| **Licht-/Gerätegruppen** | YAML oder UI — aber in `docs/lights.md` listen | Gruppen in Doku; Quelle prüfen |
| **Utility Meter / Statistik** | YAML wenn Automationen darauf bauen | Einzelfall |
| **Customize** (`homeassistant.customize`) | YAML in `configuration.yaml` | ✅ z. B. Müll-Icons, Zähler |
| **Automation per UI erstellt** | Abspeichern nach `automations.yaml` verlagern | Bereits YAML-Mode für Automationen |
| **HACS-Frontend** (Mushroom) | Ressource in YAML nach Dashboard-Migration | Derzeit teils `lovelace_resources` in Storage |
| **Node-RED** (falls je genutzt) | Eigener Flow — nicht in diesem Repo | — |

**Regel:** Wenn die KI es ändern soll → YAML + Spec. Wenn nur du es anfasst → UI, aber in `/docs` erwähnen.

---

## Konkreter Migrations-Backlog (Stand Repo)

Abgleich mit dem, was noch in `.storage` steckt:

- [x] **Helpers** (`input_*`) → `helpers.yaml` (Package); UI-Helfer gelöscht, `.storage/input_*` geleert, Neustart ohne Warnungen
- [ ] **Skripte** prüfen → `scripts.yaml`
- [ ] **Dashboards** nacheinander → `dashboards/*.yaml` (Start: `test`, dann `Tablett`, zuletzt `Übersicht`)
- [ ] **Lovelace-Ressourcen** in YAML überführen
- [ ] README-Links zu fehlenden Docs (`appliances.md`, `lighting.md` vs. `lights.md`) bereinigen

Bereits in YAML und gut: `automations.yaml`, `scenes.yaml`, Templates in `configuration.yaml`, Zigbee2MQTT-Namen, ESPHome.

---

## Sicher arbeiten (YAML)

1. **Snapshot** (HA-Backup) vor größeren Schritten  
2. **Einstellungen → System → YAML-Konfiguration prüfen**  
3. **Klein committen** — ein Bereich pro Commit  
4. Fehler in `configuration.yaml` sind am kritischsten; Dashboard-/Automation-Fehler oft lokal begrenzt  

Details: Abschnitt „Sicherheit“ in der ursprünglichen Migrations-Diskussion — bei Unsicherheit zuerst Spec, dann kleinster YAML-Schritt.

---

## Für die KI (Kurzfassung)

| Aktion | Erlaubt ohne Rückfrage | Nur mit Spec / Nutzer |
|--------|------------------------|------------------------|
| `automations.yaml`, `scenes.yaml`, `scripts.yaml` | Nach Spec | — |
| `configuration.yaml` (template, input_*, lovelace) | Nach Spec | Große Umbauten ankündigen |
| `docs/*` | Spec schreiben/aktualisieren | — |
| `zigbee2mqtt/`, `esphome/` | Nach Spec + Inventar-Doku | Pairing |
| `.storage/*` | **Nein** | — |
| Integration neu hinzufügen | **Nein** (du in UI) | Doku-Eintrag |

---

## Siehe auch

- [`standards.md`](./standards.md) — Naming, UI (Mushroom/Glue), KI-Workflow  
- [`lights.md`](./lights.md) — Entity-Inventar Beleuchtung  
- [`README.md`](../README.md) — Vision & Roadmap  
