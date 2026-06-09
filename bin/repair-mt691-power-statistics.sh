#!/bin/sh
# Bereinigt Leistungs-Statistik (mean) nach Tasmota-Artefakten (999999 W → ~870 kW in Stromquellen).

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
MAX_MEAN="${MAX_MEAN:-25000}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

if [ -n "${META_ID:-}" ]; then
  echo "Reparatur Leistung, meta $META_ID (override)"
else
  META_ID="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.mt691_power_cur_stabil' LIMIT 1;" 2>/dev/null || true)"
fi
if [ -z "$META_ID" ]; then
  META_ID="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.tasmota_mt691_power_cur' LIMIT 1;")"
  echo "Reparatur auf Roh-Meta $META_ID (stabil noch ohne statistics_meta)"
else
  echo "Reparatur Leistung stabil, meta $META_ID"
fi

for table in statistics statistics_short_term; do
  mariadb_cmd -e "
  UPDATE $table t
  JOIN (
    SELECT t2.id,
      (SELECT p.mean FROM $table p
       WHERE p.metadata_id = $META_ID AND p.start_ts < t2.start_ts AND p.mean <= $MAX_MEAN
       ORDER BY p.start_ts DESC LIMIT 1) AS prev_mean
    FROM $table t2
    WHERE t2.metadata_id = $META_ID AND t2.mean > $MAX_MEAN
  ) x ON t.id = x.id
  SET t.mean = IFNULL(x.prev_mean, 0);
  "
  n="$(mariadb_cmd -N -e "SELECT COUNT(*) FROM $table WHERE metadata_id=$META_ID AND mean > $MAX_MEAN;")"
  echo "$table: $n Zeilen mit mean > $MAX_MEAN verbleibend"
done

echo "Leistungs-Statistik-Reparatur abgeschlossen."
