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
- Empfehlung: Add-on **stoppen**, wenn die neue Integration stabil läuft (ein Ziel reicht).
- Nicht beides langfristig pflegen, ohne Grund.

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
