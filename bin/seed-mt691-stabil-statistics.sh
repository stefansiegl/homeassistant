#!/bin/sh
# Kopiert reparierte Strom-Statistik Roh → stabil (einmalig nach Migration).
# Quelle: sensor.tasmota_mt691_total_in / total_out
# Ziel:   sensor.mt691_total_in_stabil / mt691_total_out_stabil

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

META_SRC_IN="${META_SRC_IN:-475}"
META_SRC_OUT="${META_SRC_OUT:-476}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

meta_dst() {
  statistic_id="$1"
  mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='$statistic_id' LIMIT 1;"
}

seed_pair() {
  src="$1"
  dst_stat="$2"
  label="$3"
  dst="$(meta_dst "$dst_stat")"
  [ -n "$dst" ] || {
    echo "$dst_stat noch ohne statistics_meta — Core-Neustart abwarten." >&2
    exit 1
  }
  echo "Seed $label: meta $src → $dst ($dst_stat)"
  mariadb_cmd -e "
  START TRANSACTION;
  DELETE FROM statistics WHERE metadata_id = $dst;
  DELETE FROM statistics_short_term WHERE metadata_id = $dst;
  INSERT INTO statistics (created_ts, metadata_id, start_ts, state, sum)
  SELECT created_ts, $dst, start_ts, state, sum
  FROM statistics WHERE metadata_id = $src;
  INSERT INTO statistics_short_term (created_ts, metadata_id, start_ts, state, sum)
  SELECT created_ts, $dst, start_ts, state, sum
  FROM statistics_short_term WHERE metadata_id = $src;
  COMMIT;
  "
}

seed_pair "$META_SRC_IN" "sensor.mt691_total_in_stabil" "Netzbezug"
seed_pair "$META_SRC_OUT" "sensor.mt691_total_out_stabil" "Einspeisung"
echo "MT691-Stabil-Seed abgeschlossen."
