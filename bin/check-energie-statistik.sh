#!/bin/sh
# Kurz-Diagnose Recorder-Statistik für Energie-Dashboard (Strom/Gas/Wasser).
# Zeigt Monats-Deltas und auffällige sum-Sprünge der letzten 7 Tage.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

echo "=== Monats-Verbrauch (aktueller Monat, Summe stündlicher Deltas) ==="
mariadb_cmd -e "
SELECT quelle, ROUND(SUM(GREATEST(0, d_verbrauch)), 2) AS verbrauch
FROM (
  SELECT 'Strom Bezug kWh' AS quelle,
    v.sum - LAG(v.sum) OVER (ORDER BY v.start_ts) AS d_verbrauch
  FROM statistics v
  WHERE v.metadata_id=475
    AND v.start_ts >= UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-01'))
    AND v.start_ts < UNIX_TIMESTAMP(DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-01'))
  UNION ALL
  SELECT 'Gas m³',
    v.sum - LAG(v.sum) OVER (ORDER BY v.start_ts)
  FROM statistics v
  WHERE v.metadata_id=COALESCE(
    (SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil' LIMIT 1), 848)
    AND v.start_ts >= UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-01'))
    AND v.start_ts < UNIX_TIMESTAMP(DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-01'))
  UNION ALL
  SELECT 'Wasser stabil m³',
    v.sum - LAG(v.sum) OVER (ORDER BY v.start_ts)
  FROM statistics v
  WHERE v.metadata_id=1266
    AND v.start_ts >= UNIX_TIMESTAMP(DATE_FORMAT(NOW(), '%Y-%m-01'))
    AND v.start_ts < UNIX_TIMESTAMP(DATE_FORMAT(NOW() + INTERVAL 1 MONTH, '%Y-%m-01'))
) m
GROUP BY quelle;
"

echo ""
echo "=== Auffällige Verbrauch-sum-Sprünge (letzte 7 Tage) ==="
mariadb_cmd -e "
SELECT quelle, ts, d_sum FROM (
  SELECT 'Strom Bezug' AS quelle, FROM_UNIXTIME(v.start_ts) AS ts,
    ROUND(v.sum-LAG(v.sum) OVER (ORDER BY v.start_ts),2) AS d_sum
  FROM statistics v
  WHERE v.metadata_id=475
    AND v.start_ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
) strom WHERE ABS(IFNULL(d_sum,0)) > 50
UNION ALL
SELECT quelle, ts, d_sum FROM (
  SELECT 'Gas' AS quelle, FROM_UNIXTIME(v.start_ts) AS ts,
    ROUND(v.sum-LAG(v.sum) OVER (ORDER BY v.start_ts),2) AS d_sum
  FROM statistics v
  WHERE v.metadata_id=COALESCE(
    (SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil' LIMIT 1), 848)
    AND v.start_ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
) gas WHERE ABS(IFNULL(d_sum,0)) > 5
UNION ALL
SELECT quelle, ts, d_sum FROM (
  SELECT 'Wasser stabil' AS quelle, FROM_UNIXTIME(v.start_ts) AS ts,
    ROUND(v.sum-LAG(v.sum) OVER (ORDER BY v.start_ts),2) AS d_sum
  FROM statistics v
  WHERE v.metadata_id=1266
    AND v.start_ts >= UNIX_TIMESTAMP(NOW() - INTERVAL 7 DAY)
) wasser WHERE ABS(IFNULL(d_sum,0)) > 1
ORDER BY ts;
"
