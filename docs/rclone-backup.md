# Rclone Backup Add-on

Zweites Cloud-Backup neben **Home Assistant Google Drive Backup** — synchronisiert `/backup` per rclone (flexibel, ggf. anderer Ordner/Anbieter).

## Status (Repo)

| Punkt | Wert |
|-------|------|
| Entscheidung | **Nicht aktiv** — Backup über native Google-Drive-Integration (06/2026), siehe [`backup-strategie.md`](./backup-strategie.md) |
| Add-on | `19a172aa_rclone_backup` v3.4.1 (kann gestoppt bleiben) |
| Config | `/config/rclone.conf` (unvollständig / ohne OAuth-Token) |

## Einrichtung Google Drive (einmalig, OAuth)

Die **Web UI** (Ingress) zeigt bei manchen Setups einen schwarzen Bildschirm — dann **Remote-Auth** (empfohlen):

### Variante A: Remote-Auth (PC mit Browser)

1. Auf dem **PC** (Windows/macOS/Linux) rclone installieren, falls noch nicht vorhanden.
2. Im Terminal ausführen:

```bash
rclone authorize "drive" "eyJ1c2VfdHJhc2giOiJmYWxzZSJ9"
```

3. Google-Login im Browser abschließen.
4. Den ausgegebenen JSON-Block (beginnt mit `{"access_token":…}`) auf HA anwenden:

```bash
sh /config/bin/rclone-finish-google.sh '<JSON-Token hier>'
```

5. Prüfen: `/config/rclone.conf` enthält `[google]`; `rclone lsd google:` listet Ordner.

### Variante B: Web UI (wenn Ingress lädt)

1. **Einstellungen → Add-ons → Rclone Backup → Open Web UI**
2. **Configs → Create new config** → Name `google`, Storage **Google Drive**
3. OAuth im Browser abschließen, `use_trash`: false

### Variante C: SSH-Tunnel (ohne rclone auf dem PC)

1. Auf dem PC: `ssh -L 53682:127.0.0.1:53682 root@<HA-IP> -p <SSH-Port>`
2. In der SSH-Session: `/config/bin/rclone authorize "drive" "eyJ1c2VfdHJhc2giOiJmYWxzZSJ9"`
3. Den angezeigten Link `http://127.0.0.1:53682/auth?…` im **lokalen** Browser öffnen (Tunnel leitet auf HA weiter)
4. Token aus der Ausgabe mit `rclone-finish-google.sh` eintragen (falls nötig)

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
