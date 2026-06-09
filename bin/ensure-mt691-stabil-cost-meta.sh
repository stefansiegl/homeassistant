#!/bin/sh
# Legt statistics_meta für stabil-Kosten an, falls die Energie-UI sie erwartet.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

ensure_meta() {
  dst_stat="$1"
  unit="${2:-EUR}"
  dst_meta="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='$dst_stat' LIMIT 1;" 2>/dev/null || true)"
  if [ -z "$dst_meta" ]; then
    mariadb_cmd -e "
      INSERT INTO statistics_meta (statistic_id, source, unit_of_measurement, has_sum, mean_type)
      VALUES ('$dst_stat', 'recorder', '$unit', 1, 0);
    "
    echo "Neue statistics_meta: $dst_stat"
  fi
}

ensure_meta "sensor.mt691_total_in_stabil_cost"
ensure_meta "sensor.mt691_total_out_stabil_compensation"
