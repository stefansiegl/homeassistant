#!/bin/sh
# Repariert sum/state für sensor.mt691_total_in_stabil / _out_stabil.
# Behebt HA-Neukompilierung (sum-Sprung auf ~0 nach Entity-Umstellung).

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

export DB_HOST DB_USER DB_PASS DB_NAME

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

meta_id() {
  statistic_id="$1"
  mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='$statistic_id' LIMIT 1;" 2>/dev/null || true
}

cost_meta() {
  value_stat="$1"
  case "$value_stat" in
    sensor.mt691_total_in_stabil)
      id="$(meta_id sensor.mt691_total_in_stabil_cost)"
      [ -n "$id" ] || id="$(meta_id sensor.tasmota_mt691_total_in_cost)"
      echo "$id"
      ;;
    sensor.mt691_total_out_stabil)
      id="$(meta_id sensor.mt691_total_out_stabil_compensation)"
      [ -n "$id" ] || id="$(meta_id sensor.tasmota_mt691_total_out_compensation)"
      echo "$id"
      ;;
  esac
}

IN_META="$(meta_id sensor.mt691_total_in_stabil)"
OUT_META="$(meta_id sensor.mt691_total_out_stabil)"
[ -n "$IN_META" ] && [ -n "$OUT_META" ] || {
  echo "Stabil-Statistik-Meta fehlt — Core-Neustart abwarten." >&2
  exit 1
}

. "$SCRIPT_DIR/energie-preise.sh"

# repair_stream aus repair-grid-statistics.sh (eingebettet via Source)
# shellcheck source=/dev/null
repair_stream() {
  META_ID_VALUE="$1"
  META_ID_COST="$2"
  UNIT_PRICE="$3"
  LABEL="$4"
  MAX_JUMP="${MAX_JUMP:-35.0}"
  MAX_DROP="${MAX_DROP:-2.0}"
  GAP_HOURS="${GAP_HOURS:-48}"
  GAP_MAX_JUMP="${GAP_MAX_JUMP:-500}"
  LOW_ARTIFACT="${LOW_ARTIFACT:-5000}"

  WORKDIR="$(mktemp -d)"

  echo "=== Reparatur $LABEL (meta $META_ID_VALUE, cost $META_ID_COST) ==="

  mariadb_cmd -N -e "
    SELECT st.id, st.start_ts, st.state
    FROM statistics st WHERE st.metadata_id = $META_ID_VALUE ORDER BY st.start_ts;
  " > "$WORKDIR/hourly.tsv"

  mariadb_cmd -N -e "
    SELECT st.id, st.start_ts, st.state
    FROM statistics_short_term st WHERE st.metadata_id = $META_ID_VALUE ORDER BY st.start_ts;
  " > "$WORKDIR/short.tsv"

  fix_rows() {
    awk -v max_jump="$MAX_JUMP" -v max_drop="$MAX_DROP" \
        -v gap_hours="$GAP_HOURS" -v gap_max="$GAP_MAX_JUMP" \
        -v low_artifact="$LOW_ARTIFACT" '
    BEGIN { last = -1; last_ts = 0; last_good_ts = 0; sum = 0; prev = -1 }
    {
      id = $1; ts = $2; raw = $3 + 0
      if (last < 0) {
        fixed = raw; last = fixed; prev = fixed; last_ts = ts; last_good_ts = ts; sum = 0
        printf "%s\t%s\t%s\n", id, fixed, sum; next
      }
      gap_ref = (last_good_ts > 0) ? last_good_ts : last_ts
      hours = (ts - gap_ref) / 3600
      limit = max_jump
      if (hours > gap_hours) limit = gap_max
      fixed = raw; accepted = 0
      if (last > low_artifact && raw < low_artifact) { fixed = last }
      else if (raw - last > limit) {
        if (hours > gap_hours && raw >= last) { fixed = raw; accepted = 1 } else fixed = last
      } else if (last - raw > max_drop) { fixed = last }
      else if (raw > last * 1.05 && raw - last > 50) { fixed = last }
      else { accepted = 1 }
      if (accepted) last_good_ts = ts
      if (fixed >= prev) delta = fixed - prev; else delta = 0
      sum += delta; prev = fixed; last = fixed; last_ts = ts
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

  mariadb_cmd -N -e "SELECT id, start_ts, state FROM statistics WHERE metadata_id=$META_ID_VALUE ORDER BY start_ts;" \
    | awk 'BEGIN{prev=-1;sum=0}{id=$1;st=$3+0;if(prev<0)delta=0;else if(st>=prev)delta=st-prev;else delta=0;sum+=delta;prev=st;printf "%s\t%.6f\n",id,sum}' \
    > "$WORKDIR/statistics_sum.tsv"
  {
    echo "START TRANSACTION;"
    while IFS="$(printf '\t')" read -r id sum; do
      [ -z "$id" ] && continue
      printf "UPDATE statistics SET sum=%s WHERE id=%s;\n" "$sum" "$id"
    done < "$WORKDIR/statistics_sum.tsv"
    echo "COMMIT;"
  } | mariadb_cmd

  mariadb_cmd -e "
  UPDATE statistics_short_term st JOIN (
    SELECT st2.id,
      (SELECT h.sum FROM statistics h WHERE h.metadata_id=$META_ID_VALUE
         AND h.start_ts <= FLOOR(st2.start_ts / 3600) * 3600
       ORDER BY h.start_ts DESC LIMIT 1) AS h_sum,
      (SELECT h.state FROM statistics h WHERE h.metadata_id=$META_ID_VALUE
         AND h.start_ts <= FLOOR(st2.start_ts / 3600) * 3600
       ORDER BY h.start_ts DESC LIMIT 1) AS h_state,
      st2.state AS st_state
    FROM statistics_short_term st2 WHERE st2.metadata_id = $META_ID_VALUE
  ) c ON st.id = c.id
  SET st.sum = ROUND(IFNULL(c.h_sum, 0) + GREATEST(0, c.st_state - IFNULL(c.h_state, c.st_state)), 6);
  "

  if [ -n "$META_ID_COST" ]; then
    GAS_PRICE="$UNIT_PRICE" META_ID_VALUE="$META_ID_VALUE" META_ID_COST="$META_ID_COST" \
      sh "$SCRIPT_DIR/sync-gasmeter-cost.sh"
  fi

  rm -rf "$WORKDIR"
}

IN_COST="$(cost_meta sensor.mt691_total_in_stabil)"
OUT_COST="$(cost_meta sensor.mt691_total_out_stabil)"

repair_stream "$IN_META" "$IN_COST" "$GRID_IMPORT_PRICE" "Stabil Netzbezug"
repair_stream "$OUT_META" "$OUT_COST" "$GRID_EXPORT_PRICE" "Stabil Einspeisung"

echo "MT691-Stabil-Reparatur abgeschlossen."
