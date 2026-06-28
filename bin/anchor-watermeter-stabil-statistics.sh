#!/bin/sh
# Einmalige Korrektur der Wasser-Stabil-Statistik nach bestätigtem Zählerstand.
# Nutzung (nach Script wasser_stabil_korrigieren / stabilem OCR):
#   DB_PASS='…' ANCHOR_VALUE=157.171 /config/bin/anchor-watermeter-stabil-statistics.sh
#
# Setzt alle Stunden ab ANCHOR_FROM_TS (default: 2026-06-22) auf ANCHOR_VALUE und
# berechnet sum neu. Synchronisiert Kosten.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
ANCHOR_VALUE="${ANCHOR_VALUE:?ANCHOR_VALUE required (m³, z. B. 157.171)}"
ANCHOR_FROM_TS="${ANCHOR_FROM_TS:-1782086400}"
META_ID_VALUE="${META_ID_VALUE:-1266}"
WATER_PRICE="${WATER_PRICE:-3.52}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

META_ID_COST="$(mariadb_cmd -N -e \
  "SELECT id FROM statistics_meta WHERE statistic_id='sensor.watermeter_stabil_kosten' LIMIT 1;" 2>/dev/null || true)"
[ -n "$META_ID_COST" ] || META_ID_COST="$(mariadb_cmd -N -e \
  "SELECT id FROM statistics_meta WHERE statistic_id='sensor.watermeter_value_stabil_cost' LIMIT 1;" 2>/dev/null || true)"

echo "Anchor Wasser stabil: meta=$META_ID_VALUE ab ts=$ANCHOR_FROM_TS → $ANCHOR_VALUE m³"

mariadb_cmd -e "
START TRANSACTION;
UPDATE statistics
SET state = $ANCHOR_VALUE
WHERE metadata_id = $META_ID_VALUE AND start_ts >= $ANCHOR_FROM_TS;
UPDATE statistics_short_term
SET state = $ANCHOR_VALUE
WHERE metadata_id = $META_ID_VALUE AND start_ts >= $ANCHOR_FROM_TS;
COMMIT;
"

recalc_sum() {
  table=$1
  mariadb_cmd -N -e \
    "SELECT id, start_ts, state FROM $table WHERE metadata_id=$META_ID_VALUE ORDER BY start_ts;" \
    | awk 'BEGIN{prev=-1;sum=0}{id=$1;st=$3+0;if(prev<0)delta=0;else if(st>=prev)delta=st-prev;else delta=0;sum+=delta;prev=st;printf "%s\t%.6f\n",id,sum}' \
    | while IFS="$(printf '\t')" read -r id sum; do
        [ -z "$id" ] && continue
        mariadb_cmd -e "UPDATE $table SET sum=$sum WHERE id=$id;"
      done
}

recalc_sum statistics

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

if [ -n "$META_ID_COST" ]; then
  DB_PASS="$DB_PASS" DB_HOST="$DB_HOST" DB_USER="$DB_USER" DB_NAME="$DB_NAME" \
    GAS_PRICE="$WATER_PRICE" META_ID_VALUE="$META_ID_VALUE" META_ID_COST="$META_ID_COST" \
    sh "$SCRIPT_DIR/sync-gasmeter-cost.sh"
fi

mariadb_cmd -e "
SELECT 'hourly' tbl, COUNT(*) cnt, MIN(state) min_st, MAX(state) max_st, MAX(sum) max_sum
FROM statistics WHERE metadata_id=$META_ID_VALUE
UNION ALL
SELECT 'short', COUNT(*), MIN(state), MAX(state), MAX(sum)
FROM statistics_short_term WHERE metadata_id=$META_ID_VALUE;
"
echo "Anchor abgeschlossen."
