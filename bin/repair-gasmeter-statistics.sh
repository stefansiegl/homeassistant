#!/bin/sh
# Repariert sensor.gasmeter_value(+_cost) Statistik nach OCR-/Offline-Ausreißern.
# Liest Rohwerte NUR aus der bestehenden statistics-Tabelle (metadata 848).
# Voraussetzung: unveränderte Recorder-Daten (z. B. nach DB-Restore) — nicht nach
# fehlerhaftem Reparaturlauf erneut ausführen.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
GAS_PRICE="${GAS_PRICE:-1.32}"
META_ID_VALUE="${META_ID_VALUE:-848}"
META_ID_COST="${META_ID_COST:-1080}"
MAX_JUMP="${MAX_JUMP:-3.0}"
MAX_DROP="${MAX_DROP:-0.2}"
GAP_HOURS="${GAP_HOURS:-48}"
GAP_MAX_JUMP="${GAP_MAX_JUMP:-30}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

mariadb_cmd -N -e "
SELECT st.id, st.start_ts, st.state
FROM statistics st
WHERE st.metadata_id = $META_ID_VALUE
ORDER BY st.start_ts;
" > "$WORKDIR/hourly.tsv"

mariadb_cmd -N -e "
SELECT st.id, st.start_ts, st.state
FROM statistics_short_term st
WHERE st.metadata_id = $META_ID_VALUE
ORDER BY st.start_ts;
" > "$WORKDIR/short.tsv"

fix_rows() {
  awk -v max_jump="$MAX_JUMP" -v max_drop="$MAX_DROP" \
      -v gap_hours="$GAP_HOURS" -v gap_max="$GAP_MAX_JUMP" '
  BEGIN { last = -1; last_ts = 0; last_good_ts = 0; sum = 0; prev = -1 }
  {
    id = $1; ts = $2; raw = $3 + 0
    if (last < 0) {
      fixed = raw
      last = fixed; prev = fixed; last_ts = ts; last_good_ts = ts
      sum = 0
      printf "%s\t%s\t%s\n", id, fixed, sum
      next
    }
    gap_ref = (last_good_ts > 0) ? last_good_ts : last_ts
    hours = (ts - gap_ref) / 3600
    limit = max_jump
    if (hours > gap_hours) limit = gap_max
    fixed = raw
    accepted = 0
    if (raw - last > limit) {
      if (last < 1000 && raw > 5000) { fixed = raw; accepted = 1 }
      else if (hours > gap_hours && raw > 5000 && raw >= last) { fixed = raw; accepted = 1 }
      else fixed = last
    } else if (last - raw > max_drop) {
      fixed = last
    } else if (raw > last * 1.05 && raw - last > 10) {
      fixed = last
    } else {
      accepted = 1
    }
    if (accepted) last_good_ts = ts
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
    [ -z "$id" ] && continue
    printf "UPDATE statistics SET state=%s, sum=%s WHERE id=%s;\n" "$state" "$sum" "$id"
  done < "$WORKDIR/hourly_fixed.tsv"
  while IFS="$(printf '\t')" read -r id state sum; do
    [ -z "$id" ] && continue
    printf "UPDATE statistics_short_term SET state=%s, sum=%s WHERE id=%s;\n" "$state" "$sum" "$id"
  done < "$WORKDIR/short_fixed.tsv"
  echo "COMMIT;"
} > "$WORKDIR/updates.sql"

mariadb_cmd < "$WORKDIR/updates.sql"

# sum aus state neu (hourly/short_term getrennt berechnet — HA kann sonst am Tageswechsel
# short_term-sum in hourly übernehmen und negative Tageswerte erzeugen)
recalc_sum() {
  table=$1
  mariadb_cmd -N -e "SELECT id, start_ts, state FROM $table WHERE metadata_id=$META_ID_VALUE ORDER BY start_ts;" \
    | awk 'BEGIN{prev=-1;sum=0}{id=$1;st=$3+0;if(prev<0)delta=0;else if(st>=prev)delta=st-prev;else delta=0;sum+=delta;prev=st;printf "%s\t%.6f\n",id,sum}' \
    > "$WORKDIR/${table}_sum.tsv"
  {
    echo "START TRANSACTION;"
    while IFS="$(printf '\t')" read -r id sum; do
      [ -z "$id" ] && continue
      printf "UPDATE $table SET sum=%s WHERE id=%s;\n" "$sum" "$id"
    done < "$WORKDIR/${table}_sum.tsv"
    echo "COMMIT;"
  } | mariadb_cmd
}

recalc_sum statistics

# short_term-sum an hourly koppeln (gleiche kumulative Basis — sonst leerer Mai / -9 m³ am 08.06.)
mariadb_cmd -e "
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
  GAS_PRICE="$GAS_PRICE" META_ID_VALUE="$META_ID_VALUE" META_ID_COST="$META_ID_COST" \
  sh "$SCRIPT_DIR/sync-gasmeter-cost.sh"

echo "Reparatur abgeschlossen."
mariadb_cmd -e "
SELECT 'hourly' AS tbl, COUNT(*) cnt,
  MIN(state) min_state, MAX(state) max_state, MIN(sum) min_sum, MAX(sum) max_sum
FROM statistics st WHERE metadata_id=$META_ID_VALUE
UNION ALL
SELECT 'short', COUNT(*), MIN(state), MAX(state), MIN(sum), MAX(sum)
FROM statistics_short_term st WHERE metadata_id=$META_ID_VALUE;
"
