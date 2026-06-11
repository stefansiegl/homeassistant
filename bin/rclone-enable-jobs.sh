#!/bin/sh
# Jobs und dry_run für Rclone Backup Add-on aktivieren (nach OAuth).
set -eu
if ! grep -q '^\[google\]' /config/rclone.conf 2>/dev/null; then
  echo "FEHLER: Remote [google] fehlt in /config/rclone.conf — zuerst OAuth abschließen."
  exit 1
fi
# shellcheck disable=SC1091
source /etc/profile.d/homeassistant.sh 2>/dev/null || true
: "${SUPERVISOR_TOKEN:?SUPERVISOR_TOKEN nicht gesetzt}"
curl -sS -X POST "http://supervisor/addons/19a172aa_rclone_backup/options" \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "options": {
      "config_path": "/config/rclone.conf",
      "dry_run": false,
      "flags": {
        "drive-use-trash": false
      },
      "jobs": [
        {
          "name": "Sync Backups nach Google Drive",
          "schedule": "30 4 * * *",
          "command": "sync",
          "sources": ["/backup"],
          "destination": "google:Backup/Home Assistant/rclone",
          "include": [],
          "exclude": []
        }
      ]
    }
  }'
echo ""
ha apps restart 19a172aa_rclone_backup
echo "Fertig. Nächster Lauf: täglich 04:30."
