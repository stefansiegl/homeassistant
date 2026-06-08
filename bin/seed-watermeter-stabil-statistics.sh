#!/bin/sh
# Kopiert reparierte Wasser-Statistik von sensor.watermeter_value → sensor.watermeter_value_stabil.
# Einmalig nach Umstellung im Energie-Dashboard, damit Historie sichtbar bleibt.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
META_SRC="${META_SRC:-1083}"
META_DST="${META_DST:-1266}"
WATER_PRICE="${WATER_PRICE:-3.52}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

echo "Seed stabil: metadata $META_SRC → $META_DST"

mariadb_cmd -e "
START TRANSACTION;
DELETE FROM statistics WHERE metadata_id = $META_DST;
DELETE FROM statistics_short_term WHERE metadata_id = $META_DST;
INSERT INTO statistics (created_ts, metadata_id, start_ts, state, sum)
SELECT created_ts, $META_DST, start_ts, state, sum
FROM statistics WHERE metadata_id = $META_SRC;
INSERT INTO statistics_short_term (created_ts, metadata_id, start_ts, state, sum)
SELECT created_ts, $META_DST, start_ts, state, sum
FROM statistics_short_term WHERE metadata_id = $META_SRC;
COMMIT;
"

META_ID_COST="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.watermeter_value_stabil_cost' LIMIT 1;" || true)"
if [ -n "$META_ID_COST" ]; then
  SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
  DB_PASS="$DB_PASS" DB_HOST="$DB_HOST" DB_USER="$DB_USER" DB_NAME="$DB_NAME" \
    GAS_PRICE="$WATER_PRICE" META_ID_VALUE="$META_DST" META_ID_COST="$META_ID_COST" \
    sh "$SCRIPT_DIR/sync-gasmeter-cost.sh"
else
  echo "Hinweis: sensor.watermeter_value_stabil_cost noch ohne statistics_meta — Kosten nach Core-Neustart/sync."
fi

mariadb_cmd -e "
SELECT 'hourly' tbl, COUNT(*) cnt, MIN(state) min_st, MAX(state) max_st, MIN(sum) min_sum, MAX(sum) max_sum
FROM statistics WHERE metadata_id=$META_DST
UNION ALL
SELECT 'short', COUNT(*), MIN(state), MAX(state), MIN(sum), MAX(sum)
FROM statistics_short_term WHERE metadata_id=$META_DST;
"
echo "Seed abgeschlossen."
