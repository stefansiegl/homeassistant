#!/bin/sh
# Backfill sensor.mt691_power_cur_stabil aus Roh-Statistik (gefiltert).
# Einmalig nach Core-Neustart / Energie-UI-Umstellung auf Stabil-Leistung.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
META_SRC="${META_SRC:-898}"
MAX_MEAN="${MAX_MEAN:-25000}"
MAX_JUMP="${MAX_JUMP:-15000}"
ARTIFACT="${ARTIFACT:-999000}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

META_DST="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.mt691_power_cur_stabil' LIMIT 1;" 2>/dev/null || true)"
if [ -z "$META_DST" ]; then
  mariadb_cmd -e "
    INSERT INTO statistics_meta (statistic_id, source, unit_of_measurement, has_sum, mean_type)
    VALUES ('sensor.mt691_power_cur_stabil', 'recorder', 'W', 0, 0);
  "
  META_DST="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.mt691_power_cur_stabil' LIMIT 1;")"
  echo "Neue statistics_meta: sensor.mt691_power_cur_stabil → $META_DST"
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

filter_power() {
  awk -v max_mean="$MAX_MEAN" -v max_jump="$MAX_JUMP" -v artifact="$ARTIFACT" '
  BEGIN { last = -1 }
  {
    cts = $1; ts = $2; mean = $3 + 0; mn = $4 + 0; mx = $5 + 0
    bad = (mean < 0 || mean >= artifact || mean > max_mean || (last >= 0 && mean - last > max_jump))
    if (last < 0 && bad) {
      fixed = 0
    } else if (bad) {
      fixed = last
    } else {
      fixed = mean
    }
    if (mx >= artifact || mx > max_mean) mx = fixed
    if (mn < 0) mn = 0
    if (fixed >= 0) last = fixed
    printf "%s\t%s\t%.6f\t%.6f\t%.6f\n", cts, ts, fixed, mn, mx
  }'
}

echo "=== Backfill short_term: meta $META_SRC → $META_DST ==="
mariadb_cmd -N -e "
  SELECT IFNULL(created_ts, start_ts), start_ts,
    IFNULL(mean, 0), IFNULL(min, 0), IFNULL(max, 0)
  FROM statistics_short_term WHERE metadata_id = $META_SRC
  ORDER BY start_ts;
" | filter_power > "$WORKDIR/short_filtered.tsv"

rows="$(wc -l < "$WORKDIR/short_filtered.tsv" | tr -d ' ')"
[ "$rows" -gt 0 ] || { echo "Keine Quell-Zeilen" >&2; exit 1; }

{
  echo "START TRANSACTION;"
  echo "DELETE FROM statistics_short_term WHERE metadata_id = $META_DST;"
  echo "DELETE FROM statistics WHERE metadata_id = $META_DST;"
  while IFS="$(printf '\t')" read -r cts ts mean mn mx; do
    [ -z "$ts" ] && continue
    printf "INSERT INTO statistics_short_term (created_ts, metadata_id, start_ts, mean, min, max) VALUES (%s, %s, %s, %s, %s, %s);\n" \
      "$cts" "$META_DST" "$ts" "$mean" "$mn" "$mx"
  done < "$WORKDIR/short_filtered.tsv"
  echo "COMMIT;"
} | mariadb_cmd
echo "short_term: $rows Zeilen eingefügt"

echo "=== Stundenwerte aus short_term aggregieren ==="
mariadb_cmd -e "
INSERT INTO statistics (created_ts, metadata_id, start_ts, mean, min, max)
SELECT MIN(st.created_ts), $META_DST, FLOOR(st.start_ts / 3600) * 3600,
  AVG(st.mean), MIN(st.min), LEAST(MAX(st.max), $MAX_MEAN)
FROM statistics_short_term st
WHERE st.metadata_id = $META_DST
GROUP BY FLOOR(st.start_ts / 3600) * 3600;
"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
META_ID="$META_DST" sh "$SCRIPT_DIR/repair-mt691-power-statistics.sh" 2>/dev/null || true

mariadb_cmd -N -e "
SELECT CONCAT('hourly: ', COUNT(*), ' Zeilen, mean ', ROUND(MIN(mean),1), '–', ROUND(MAX(mean),1), ' W')
FROM statistics WHERE metadata_id=$META_DST;
SELECT CONCAT('short: ', COUNT(*), ' Zeilen')
FROM statistics_short_term WHERE metadata_id=$META_DST;
"

echo "Power-Stabil-Backfill abgeschlossen."
