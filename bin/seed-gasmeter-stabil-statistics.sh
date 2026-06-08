#!/bin/sh
# Kopiert reparierte Gas-Statistik von sensor.gasmeter_value → sensor.gasmeter_value_stabil.
# Einmalig nach Umstellung im Energie-Dashboard.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
META_SRC="${META_SRC:-848}"
META_DST="${META_DST:-}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

if [ -z "$META_DST" ]; then
  META_DST="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil' LIMIT 1;")"
fi
[ -n "$META_DST" ] || { echo "sensor.gasmeter_value_stabil noch ohne statistics_meta — Core-Neustart abwarten." >&2; exit 1; }

echo "Seed gas stabil: metadata $META_SRC → $META_DST"

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

mariadb_cmd -e "
SELECT 'hourly' tbl, COUNT(*) cnt, MIN(state) min_st, MAX(state) max_st, MIN(sum) min_sum, MAX(sum) max_sum
FROM statistics WHERE metadata_id=$META_DST
UNION ALL
SELECT 'short', COUNT(*), MIN(state), MAX(state), MIN(sum), MAX(sum)
FROM statistics_short_term WHERE metadata_id=$META_DST;
"
echo "Seed abgeschlossen."
