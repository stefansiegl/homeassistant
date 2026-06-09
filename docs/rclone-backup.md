# Rclone Backup Add-on

Zweites Cloud-Backup neben **Home Assistant Google Drive Backup** — synchronisiert `/backup` per rclone (flexibel, ggf. anderer Ordner/Anbieter).

## Status (Repo)

| Punkt | Wert |
|-------|------|
| Add-on | `19a172aa_rclone_backup` v3.4.1 |
| Config | `/config/rclone.conf` |
| Boot | **manual** (kein Autostart bis Google-Remote steht) |
| Jobs | **leer** (bis Remote `google` existiert) |
| `dry_run` | **true** (erst nach Test auf false) |

## Einrichtung Google Drive (einmalig, UI)

1. **Einstellungen → Add-ons → Rclone Backup → Starten** (läuft)
2. **Open Web UI** → Login (ohne Passwort)
3. **Configs → Create new config**
   - Name: `google`
   - Storage: **Google Drive**
   - OAuth im Browser abschließen
   - `use_trash`: false (empfohlen)
4. Prüfen: `/config/rclone.conf` enthält `[google]`-Block

## Jobs aktivieren (nach OAuth)

In der Add-on-Konfiguration (UI) oder per API:

```yaml
config_path: /config/rclone.conf
dry_run: false   # nach erfolgreichem Test
flags:
  drive-use-trash: false
jobs:
  - name: Sync Backups nach Google Drive
    schedule: "30 4 * * *"   # nach HA-Backup (~03:42) + Google-Drive-Backup
    command: sync
    sources:
      - /backup
    destination: "google:Backup/Home Assistant/rclone"
    include: []
    exclude: []
```

Zielordner `rclone` liegt **neben** dem Google-Drive-Backup-Add-on — keine Überschreibung.

Optional Boot wieder aktivieren: Add-on → **Start bei Boot: an**.

## Fehlerbilder

| Symptom | Ursache | Fix |
|---------|---------|-----|
| `boot_fail` / Add-on nicht installiert | Fehlende `rclone.conf` + Boot | Add-on installieren, Boot **manual** |
| `remote 'google:' does not exist` | Job ohne Remote | Jobs leer lassen bis OAuth fertig |
| `rclone config not found` | Nur Kommentare, kein Remote | Web UI: Remote anlegen |

## Abgrenzung

- **Google Drive Backup** (`cebe7a76`): dediziertes HA-Backup mit UI/Wiederherstellung
- **Rclone**: generischer Sync (z. B. zweite Kopie, andere Filter, später SFTP/Crypt)
