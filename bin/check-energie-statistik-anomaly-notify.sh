#!/bin/sh
# Schreibt Anomalie-Marker für HA-File-Sensor; Log bei Befund.

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
MARKER="/config/.energie_statistik_anomaly"

MSG="$(sh "$SCRIPT_DIR/check-energie-statistik-anomaly.sh" --message 2>/dev/null || true)"
RET=$?

if [ "$RET" -ne 0 ] && [ -n "$MSG" ]; then
  printf '%s\n' "$MSG" > "$MARKER"
  echo "$MSG" >&2
  exit 1
fi

rm -f "$MARKER"
exit 0
