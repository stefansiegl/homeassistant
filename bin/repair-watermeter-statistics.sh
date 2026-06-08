#!/bin/sh
# Repariert sensor.watermeter_value(+_cost) Statistik in MariaDB nach OCR-/Offline-Ausreißern.
# Kein absoluter m³-Deckel — nur Sprung-Plausibilisierung.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
WATER_PRICE="${WATER_PRICE:-3.52}"
META_ID_VALUE="${META_ID_VALUE:-1083}"
META_ID_COST="${META_ID_COST:-1082}"
MAX_JUMP="${MAX_JUMP:-2.0}"
MAX_DROP="${MAX_DROP:-0.2}"
GAP_HOURS="${GAP_HOURS:-48}"
GAP_MAX_JUMP="${GAP_MAX_JUMP:-15}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e "
SELECT st.id, st.start_ts, st.state
FROM statistics st
WHERE st.metadata_id = $META_ID_VALUE
ORDER BY st.start_ts;
" > "$WORKDIR/hourly.tsv"

mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e "
SELECT st.id, st.start_ts, st.state
FROM statistics_short_term st
WHERE st.metadata_id = $META_ID_VALUE
ORDER BY st.start_ts;
" > "$WORKDIR/short.tsv"

fix_rows() {
  awk -v max_jump="$MAX_JUMP" -v max_drop="$MAX_DROP" \
      -v gap_hours="$GAP_HOURS" -v gap_max="$GAP_MAX_JUMP" '
  BEGIN { last = -1; last_ts = 0; sum = 0; prev = -1 }
  {
    id = $1; ts = $2; raw = $3 + 0
    if (last < 0) {
      if (raw >= 50 && raw <= 2000) { fixed = raw } else { fixed = raw }
      last = fixed; prev = fixed; last_ts = ts
      sum = 0
      printf "%s\t%s\t%s\n", id, fixed, sum
      next
    }
    hours = (ts - last_ts) / 3600
    limit = max_jump
    if (hours > gap_hours) limit = gap_max
    fixed = raw
    if (raw - last > limit) fixed = last
    else if (last - raw > max_drop) fixed = last
    else if (raw > last * 3 && raw > 500) fixed = last
    if (fixed >= prev) delta = fixed - prev
    else delta = 0
    sum += delta
    prev = fixed
    last = fixed
    last_ts = ts
    printf "%s\t%.4f\t%.6f\n", id, fixed, sum
  }' "$1"
}

fix_rows "$WORKDIR/hourly.tsv" > "$WORKDIR/hourly_fixed.tsv"
fix_rows "$WORKDIR/short.tsv" > "$WORKDIR/short_fixed.tsv"

{
  echo "START TRANSACTION;"
  while IFS="$(printf '\t')" read -r id state sum; do
    printf "UPDATE statistics SET state=%s, sum=%s WHERE id=%s;\n" "$state" "$sum" "$id"
  done < "$WORKDIR/hourly_fixed.tsv"
  while IFS="$(printf '\t')" read -r id state sum; do
    printf "UPDATE statistics_short_term SET state=%s, sum=%s WHERE id=%s;\n" "$state" "$sum" "$id"
  done < "$WORKDIR/short_fixed.tsv"
  echo "COMMIT;"
} > "$WORKDIR/updates.sql"

mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$WORKDIR/updates.sql"

recalc_sum() {
  table=$1
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
    "SELECT id, start_ts, state FROM $table WHERE metadata_id=$META_ID_VALUE ORDER BY start_ts;" \
    | awk 'BEGIN{prev=-1;sum=0}{id=$1;st=$3+0;if(prev<0)delta=0;else if(st>=prev)delta=st-prev;else delta=0;sum+=delta;prev=st;printf "%s\t%.6f\n",id,sum}' \
    > "$WORKDIR/${table}_sum.tsv"
  {
    echo "START TRANSACTION;"
    while IFS="$(printf '\t')" read -r id sum; do
      [ -z "$id" ] && continue
      printf "UPDATE $table SET sum=%s WHERE id=%s;\n" "$sum" "$id"
    done < "$WORKDIR/${table}_sum.tsv"
    echo "COMMIT;"
  } | mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
}

recalc_sum statistics

# short_term-sum an hourly koppeln (gleiche kumulative Basis — sonst leere Tage / negative Deltas)
mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
UPDATE statistics_short_term st
JOIN (
  SELECT st2.id,
    (SELECT h.sum FROM statistics h WHERE h.metadata_id=$META_ID_VALUE
       AND h.start_ts <= FLOOR(st2.start_ts / 3600) * 3600
     ORDER BY h.start_ts DESC LIMIT 1) AS h_sum,
    (SELECT h.state FROM statistics h WHERE h.metadata_id=$META_ID_VALUE
       AND h.start_ts <= FLOOR(st2.start_ts / 3600) * 3600
     ORDER BY h.start_ts DESC LIMIT 1) AS h_state,
    st2.state AS st_state
  FROM statistics_short_term st2
  WHERE st2.metadata_id = $META_ID_VALUE
) c ON st.id = c.id
SET st.sum = ROUND(IFNULL(c.h_sum, 0) + GREATEST(0, c.st_state - IFNULL(c.h_state, c.st_state)), 6);
"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DB_PASS="$DB_PASS" DB_HOST="$DB_HOST" DB_USER="$DB_USER" DB_NAME="$DB_NAME" \
  GAS_PRICE="$WATER_PRICE" META_ID_VALUE="$META_ID_VALUE" META_ID_COST="$META_ID_COST" \
  sh "$SCRIPT_DIR/sync-gasmeter-cost.sh"

echo "Reparatur abgeschlossen."
mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
SELECT 'hourly' as tbl, COUNT(*) cnt,
  MIN(state) min_state, MAX(state) max_state, MIN(sum) min_sum, MAX(sum) max_sum
FROM statistics st WHERE metadata_id=$META_ID_VALUE
UNION ALL
SELECT 'short', COUNT(*), MIN(state), MAX(state), MIN(sum), MAX(sum)
FROM statistics_short_term st WHERE metadata_id=$META_ID_VALUE;
"
