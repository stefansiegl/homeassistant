#!/bin/sh
# Synchronisiert Kosten-Statistik aus Verbrauchs-statistics.state × Preis.
# Legt fehlende Kosten-Zeilen an (Energie-Dashboard: vor Sensor-Start 2026 oft 0 € trotz m³).
# Kosten = val.state × Preis (absoluter Zählerstand wie Template-Kostensensoren).
# NICHT val.sum — der Recorder setzt bei total_increasing einen eigenen Nullpunkt (sum ≠ state).
# Perioden im Dashboard = Deltas der sum-Spalte der Kosten-Statistik.

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

GAS_PRICE="${GAS_PRICE:-1.32}"
META_ID_VALUE="${META_ID_VALUE:-848}"
META_ID_COST="${META_ID_COST:-1080}"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

echo "Kosten-Sync: value meta=$META_ID_VALUE, cost meta=$META_ID_COST, Preis=$GAS_PRICE"

mariadb_cmd -e "
SET @price := $GAS_PRICE;
SET @val_meta := $META_ID_VALUE;
SET @cost_meta := $META_ID_COST;

INSERT INTO statistics (created_ts, created, start_ts, start, state, sum, metadata_id)
SELECT
  val.start_ts,
  UTC_TIMESTAMP(6),
  val.start_ts,
  FROM_UNIXTIME(val.start_ts),
  ROUND(val.state * @price, 6),
  ROUND(val.state * @price, 6),
  @cost_meta
FROM statistics val
LEFT JOIN statistics cost
  ON cost.metadata_id = @cost_meta AND cost.start_ts = val.start_ts
WHERE val.metadata_id = @val_meta
  AND cost.id IS NULL;

INSERT INTO statistics_short_term (created_ts, created, start_ts, start, state, sum, metadata_id)
SELECT
  val.start_ts,
  UTC_TIMESTAMP(6),
  val.start_ts,
  FROM_UNIXTIME(val.start_ts),
  ROUND(val.state * @price, 6),
  ROUND(val.state * @price, 6),
  @cost_meta
FROM statistics_short_term val
LEFT JOIN statistics_short_term cost
  ON cost.metadata_id = @cost_meta AND cost.start_ts = val.start_ts
WHERE val.metadata_id = @val_meta
  AND cost.id IS NULL;

UPDATE statistics cost
JOIN statistics val ON cost.start_ts = val.start_ts
  AND cost.metadata_id = @cost_meta
  AND val.metadata_id = @val_meta
SET cost.state = ROUND(val.state * @price, 6),
    cost.sum = ROUND(val.state * @price, 6);

UPDATE statistics_short_term cost
JOIN statistics_short_term val ON cost.start_ts = val.start_ts
  AND cost.metadata_id = @cost_meta
  AND val.metadata_id = @val_meta
SET cost.state = ROUND(val.state * @price, 6),
    cost.sum = ROUND(val.state * @price, 6);
"

mariadb_cmd -N -e "
SELECT CONCAT('hourly cost rows: ', COUNT(*)) FROM statistics WHERE metadata_id = $META_ID_COST;
SELECT CONCAT('Oct 2025 Δ: ', ROUND(MAX(cost.sum)-MIN(cost.sum), 2), ' € (',
  ROUND(MAX(val.sum)-MIN(val.sum), 2), ' m³)')
FROM statistics val JOIN statistics cost ON val.start_ts=cost.start_ts
  AND val.metadata_id=$META_ID_VALUE AND cost.metadata_id=$META_ID_COST
WHERE val.start_ts>=UNIX_TIMESTAMP('2025-10-01') AND val.start_ts<UNIX_TIMESTAMP('2025-11-01');
SELECT CONCAT('Nov 2025 Δ: ', ROUND(MAX(cost.sum)-MIN(cost.sum), 2), ' €')
FROM statistics val JOIN statistics cost ON val.start_ts=cost.start_ts
  AND val.metadata_id=$META_ID_VALUE AND cost.metadata_id=$META_ID_COST
WHERE val.start_ts>=UNIX_TIMESTAMP('2025-11-01') AND val.start_ts<UNIX_TIMESTAMP('2025-12-01');
SELECT CONCAT('Jan 2026 Δ: ', ROUND(MAX(cost.sum)-MIN(cost.sum), 2), ' €')
FROM statistics val JOIN statistics cost ON val.start_ts=cost.start_ts
  AND val.metadata_id=$META_ID_VALUE AND cost.metadata_id=$META_ID_COST
WHERE val.start_ts>=UNIX_TIMESTAMP('2026-01-01') AND val.start_ts<UNIX_TIMESTAMP('2026-02-01');
"

echo "Kosten-Sync abgeschlossen."
