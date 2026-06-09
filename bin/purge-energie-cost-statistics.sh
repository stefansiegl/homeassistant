#!/bin/sh
# Entfernt Recorder-Statistik der HA-Kosten-Sensoren (*_cost).
# WARNUNG: Das Energie-Dashboard liest Kosten aus diesen Statistik-Entities
# (energy/info → cost_sensors). Nach Purge sind Kosten = 0 bis sync-gasmeter-cost.sh
# erneut läuft. Nicht mehr automatisch aus repair-energie-dashboard.sh aufrufen.
# HA schreibt Live-Kosten oft falsch → Minus-Tageswerte; daher recorder.exclude.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

IDS="$(mariadb_cmd -N -e "
SELECT id FROM statistics_meta
WHERE statistic_id IN (
  'sensor.tasmota_mt691_total_in_cost',
  'sensor.tasmota_mt691_total_out_compensation',
  'sensor.gasmeter_value_cost',
  'sensor.gasmeter_value_stabil_cost',
  'sensor.gasmeter_value_stabil_cost_2',
  'sensor.watermeter_value_cost',
  'sensor.watermeter_value_stabil_cost'
);
")"

if [ -z "$IDS" ]; then
  echo "Keine Kosten-metadata_ids gefunden."
  exit 0
fi

echo "Purge Kosten-Statistik für metadata_ids: $IDS"
for id in $IDS; do
  mariadb_cmd -e "DELETE FROM statistics WHERE metadata_id=$id;"
  mariadb_cmd -e "DELETE FROM statistics_short_term WHERE metadata_id=$id;"
  echo "  metadata $id geleert"
done
echo "Purge abgeschlossen."
