#!/usr/bin/env bash
# Cron-Job für nächtlichen Live-Audit (22:00 Europe/Berlin ≈ 20:00 UTC Sommer / 21:00 UTC Winter)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRON_LINE="0 22 * * * $ROOT/bin/audit-live-nightly.sh >> $ROOT/log/live-audit-nightly.log 2>&1"
CRONTAB="/etc/crontabs/root"

if [[ ! -x "$ROOT/bin/audit-live-nightly.sh" ]]; then
  echo "Fehler: $ROOT/bin/audit-live-nightly.sh fehlt oder nicht ausführbar" >&2
  exit 1
fi

mkdir -p "$ROOT/log"

if [[ -f "$CRONTAB" ]] && grep -qF "audit-live-nightly.sh" "$CRONTAB"; then
  echo "Cron-Eintrag bereits vorhanden:"
  grep "audit-live-nightly" "$CRONTAB"
  exit 0
fi

echo "$CRON_LINE" >> "$CRONTAB"
# Alpine/BusyBox crond neu laden
if command -v crond >/dev/null 2>&1; then
  crond -b -l 8 2>/dev/null || true
fi

echo "Installiert:"
grep "audit-live-nightly" "$CRONTAB"
echo ""
echo "Läuft täglich um 22:00 (System-Zeitzone). Log: $ROOT/log/live-audit-nightly.log"
