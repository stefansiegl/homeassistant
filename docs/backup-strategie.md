# Backup-Strategie

Stand der Datensicherung für „Das gesunde Haus“ — was wo liegt und was bei Wiederherstellung nötig ist.

## Übersicht (Schichten)

| Schicht | Was | Zweck |
|--------|-----|--------|
| **GitHub** | YAML, Automationen, Docs, Dashboards | Versionierung, Config nachziehen |
| **HA-Snapshots lokal** | Supervisor-Backups auf dem Host | Schnelle Wiederherstellung auf dem Gerät |
| **Google Drive** (Integration) | Verschlüsselte HA-Backups in Google Drive | Offsite, vollständige Restore inkl. `.storage` |
| **Nabu Casa** | Fernzugriff, Assistenten | **Kein** Backup-Ersatz |
| **Rclone** | — | **Nicht aktiv** (bewusst verworfen, siehe unten) |

## Google Drive (native Integration, aktiv seit 06/2026)

- **Integration:** Einstellungen → Geräte & Dienste → **Google Drive**
- **Backup-Ziel:** Einstellungen → System → **Backups** → Google Drive
- **Ordner in Drive:** `Home Assistant` (pro Instanz Unterordner)
- **OAuth:** Eigener Google-Cloud-Client; Redirect-URI `https://my.home-assistant.io/redirect/oauth` (+ ggf. lokale Callback-URI)
- **Verschlüsselung:** Backup-Verschlüsselungscode in **Passwort-Manager** + Notfallset-PDF (nicht im Git, nicht in `secrets.yaml`)

### Wiederherstellung

1. HA neu installieren / leere Instanz
2. Google-Drive-Integration verknüpfen (gleicher Google-Account)
3. Backup aus Drive wählen → **Verschlüsselungscode** eingeben
4. Optional danach: Git-Config angleichen, Add-ons neu starten

## GitHub (Repo)

- Sichert **Konfiguration als Code**, nicht den Laufzeit-Zustand.
- Fehlt in Git: `.storage`, Recorder-DB, Add-on-Daten, `secrets.yaml`.
- Nach Restore aus Drive: Repo-Stand prüfen, ob YAML noch passt.

## Add-on „Home Assistant Google Drive Backup“ (`cebe7a76`)

- Lief historisch parallel; Uploads funktionierten.
- Seit **Google-Drive-Integration** (06/2026) ist das **redundant**.
- **Gestoppt seit 2026-08-23** (`boot: auto` respektiert das, kommt beim Neustart nicht von selbst wieder).
- Nicht beides langfristig pflegen, ohne Grund.

## Vorfall 2026-08-23: Cloud/Drive-Uploads schlugen 2,5 Monate lang still fehl

**Symptom:** `last_completed_automatic_backup` hing seit 2026-06-10 fest, obwohl täglich versucht wurde — nur die lokale Kopie kam an. Auffiel nur, weil wir zufällig ein Add-on-Update planten und `docs/backup-strategie.md` gegenlasen.

**Root Cause (zwei Ebenen, nicht die vermutete Backup-Größe):**

1. `homeassistant.components.backup`-Log zeigte: *"Backup agents \['google_drive...'\] are not available"* — die Integration wurde beim Backup-Start als nicht bereit aussortiert.
2. Ursache: **OAuth-Client der Google-Cloud-Konsole stand auf „Test"** statt „In Produktion" — Test-Apps verlieren ihr Refresh-Token automatisch nach **7 Tagen**, unabhängig von Nutzung. Einmal im Juni verbunden, nach einer Woche lautlos invalide geworden.

**Fix:**
1. Google Cloud Console → OAuth-Zustimmungsbildschirm → **Branding**: alle Pflichtfelder ausfüllen (inkl. „Kontaktdaten des Entwicklers" ganz unten, leicht übersehen) — bei uns zusätzlich Platzhalter für Startseite/Datenschutz/Nutzungsbedingungen nötig, obwohl ohne `*` markiert (Google-Formular-Inkonsistenz zwischen Speichern und Veröffentlichen).
2. Zielgruppe-Seite → **Veröffentlichungsstatus auf „In Produktion"** (kein Google-Review nötig bei nicht-sensiblem Scope `drive.file`).
3. HA: Google-Drive-Integration **erneut authentifizieren**.

**Lehre:** Größe (22,8 GB, wegen `include_all_addons: true` + Media) war eine Sackgasse — reduzierte Backup-Größe auf ~1-2 GB (gezielte App-Auswahl: MariaDB, Zigbee2MQTT, Grocy, ESPHome, Mosquitto; **ohne** InfluxDB [nur Grafana-Kopie der MariaDB-Daten] und Music Assistant [Cache, rebuildbar]), aber der eigentliche Fehler lag nie an der Größe. Erst der neue `binary_sensor.zigbee2mqtt_warnung`-Vorfall am selben Tag brachte uns dazu, die Backup-Konfiguration überhaupt zu prüfen — Ansporn für weitere Haus-Warnungen-Checks (siehe `docs/haus-warnungen.md`, Backlog).

## Rclone Backup (`19a172aa`)

- **Status:** gestoppt bzw. nicht eingerichtet (OAuth zu umständlich, kein Mehrwert neben Drive-Integration).
- Doku bleibt als Referenz: [`rclone-backup.md`](./rclone-backup.md).

## Vor größeren Änderungen

1. Manuelles HA-Backup (Einstellungen → System → Backups)
2. Git commit/push der Config-Änderungen
3. Erst dann: Core-Update, Add-on-Updates, YAML-Umbauten

## MariaDB / Recorder

- Recorder-Daten sind **in HA-Snapshots** enthalten, nicht in Git.
- Gezielter DB-Restore nur bei Statistik-Reparaturen — siehe [`ai-on-the-edge.md`](./ai-on-the-edge.md) (Abschnitt MariaDB).
