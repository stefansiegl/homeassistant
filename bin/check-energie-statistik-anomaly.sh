#!/bin/sh
# Prüft Recorder-Statistik auf auffällige Sprünge. Exit 0 = ok, 1 = Anomalie.
# Optionen: --count (nur Anzahl), --message (nur Text für Notify)

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
MODE="${1:-}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

strom_meta() {
  id="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.mt691_total_in_stabil' LIMIT 1;" 2>/dev/null || true)"
  if [ -n "$id" ]; then echo "$id"; else echo 475; fi
}

gas_meta() {
  mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil' LIMIT 1;" 2>/dev/null \
    || echo 848
}

STROM_META="$(strom_meta)"
GAS_META="$(gas_meta)"

MSG="$(mariadb_cmd -N -e "
SELECT GROUP_CONCAT(line SEPARATOR '; ')
FROM (
  SELECT CONCAT(quelle, ' ', ts, ': Δ=', d_sum) AS line
  FROM (
    SELECT 'Strom' AS quelle, FROM_UNIXTIME(v.start_ts) AS ts,
      ROUND(v.sum-LAG(v.sum) OVER (ORDER BY v.start_ts),2) AS d_sum
    FROM statistics v
    WHERE v.metadata_id=$STROM_META
      AND v.start_ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
  ) s WHERE ABS(IFNULL(d_sum,0)) > 50
  UNION ALL
  SELECT CONCAT(quelle, ' ', ts, ': Δ=', d_sum)
  FROM (
    SELECT 'Gas' AS quelle, FROM_UNIXTIME(v.start_ts) AS ts,
      ROUND(v.sum-LAG(v.sum) OVER (ORDER BY v.start_ts),2) AS d_sum
    FROM statistics v
    WHERE v.metadata_id=$GAS_META
      AND v.start_ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
  ) g WHERE ABS(IFNULL(d_sum,0)) > 5
  UNION ALL
  SELECT CONCAT(quelle, ' ', ts, ': Δ=', d_sum)
  FROM (
    SELECT 'Wasser' AS quelle, FROM_UNIXTIME(v.start_ts) AS ts,
      ROUND(v.sum-LAG(v.sum) OVER (ORDER BY v.start_ts),2) AS d_sum
    FROM statistics v
    WHERE v.metadata_id=1266
      AND v.start_ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
  ) w WHERE ABS(IFNULL(d_sum,0)) > 1
) x;
" 2>/dev/null || true)"

COUNT=0
if [ -n "$MSG" ] && [ "$MSG" != "NULL" ]; then
  COUNT="$(printf '%s' "$MSG" | awk -F';' '{print NF}')"
fi

case "$MODE" in
  --count) echo "$COUNT"; exit "$([ "$COUNT" -gt 0 ] && echo 1 || echo 0)" ;;
  --message)
    if [ "$COUNT" -gt 0 ]; then
      echo "Energie-Statistik-Anomalie: $MSG"
      exit 1
    fi
    echo ""
    exit 0
    ;;
  *)
    if [ "$COUNT" -gt 0 ]; then
      echo "ANOMALIE ($COUNT): $MSG"
      exit 1
    fi
    echo "OK — keine auffälligen Sprünge (7 Tage)."
    exit 0
    ;;
esac
