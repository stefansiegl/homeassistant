#!/bin/sh
# Repariert sensor.helios_luftung_energy nach Powercalc-Neuanlage (Zähler-Reset).
# Symptom: Energie-Dashboard zeigt ~-60 kWh, wenn alte sum (~62) und neuer state (~0) kollidieren.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
META_ID="${META_ID:-493}"
RESET_AFTER="${RESET_AFTER:-}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

if [ -z "$RESET_AFTER" ]; then
  # Erster Punkt nach langer Lücke (>7 Tage), an dem state auf nahe 0 fällt (Powercalc-Reset)
  RESET_AFTER="$(mariadb_cmd -N -e "
    SELECT FROM_UNIXTIME(r.start_ts)
    FROM statistics r
    JOIN statistics p ON p.metadata_id=r.metadata_id
      AND p.start_ts = (
        SELECT MAX(s2.start_ts) FROM statistics s2
        WHERE s2.metadata_id=r.metadata_id AND s2.start_ts < r.start_ts
      )
    WHERE r.metadata_id=$META_ID
      AND r.state < 1
      AND p.state > 10
      AND (r.start_ts - p.start_ts) > 7 * 86400
    ORDER BY r.start_ts DESC
    LIMIT 1;
  ")"
fi

if [ -z "$RESET_AFTER" ] || [ "$RESET_AFTER" = "NULL" ]; then
  echo "Kein Powercalc-Reset (Lücke + state < 1 nach state > 10) — nichts zu tun."
  exit 0
fi

echo "Helios-Reparatur: lösche Statistik vor $RESET_AFTER (metadata $META_ID)"

mariadb_cmd -e "
DELETE FROM statistics
WHERE metadata_id=$META_ID AND start_ts < UNIX_TIMESTAMP('$RESET_AFTER');
DELETE FROM statistics_short_term
WHERE metadata_id=$META_ID AND start_ts < UNIX_TIMESTAMP('$RESET_AFTER');
"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

recalc_sum() {
  table=$1
  mariadb_cmd -N -e "SELECT id, start_ts, state FROM $table WHERE metadata_id=$META_ID ORDER BY start_ts;" \
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
recalc_sum statistics_short_term

mariadb_cmd -e "
SELECT 'hourly' tbl, COUNT(*) cnt, ROUND(MIN(state),3) min_st, ROUND(MAX(state),3) max_st,
  ROUND(MIN(sum),3) min_sum, ROUND(MAX(sum),3) max_sum
FROM statistics WHERE metadata_id=$META_ID
UNION ALL
SELECT 'short', COUNT(*), ROUND(MIN(state),3), ROUND(MAX(state),3),
  ROUND(MIN(sum),3), ROUND(MAX(sum),3)
FROM statistics_short_term WHERE metadata_id=$META_ID;
"
echo "Helios-Reparatur abgeschlossen."
