#!/bin/sh
# Manuelle Reparatur Energie-Dashboard (Notfall / Migration) — NICHT per Cron.
# Standard-Migration: migrate-energie-statistik.sh
#
# Nutzung:
#   DB_PASS='…' /config/bin/repair-energie-dashboard.sh

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
  fallback="$2"
  id="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='$statistic_id' LIMIT 1;" 2>/dev/null || true)"
  if [ -n "$id" ]; then echo "$id"; else echo "$fallback"; fi
}

echo "========== Diagnose (vorher) =========="
sh "$SCRIPT_DIR/check-energie-statistik.sh" || true

echo ""
echo "========== Strom (Stabil, falls vorhanden) =========="
IN_META="$(meta_id sensor.mt691_total_in_stabil '')"
if [ -n "$IN_META" ]; then
  sh "$SCRIPT_DIR/repair-mt691-stabil-statistics.sh"
else
  sh "$SCRIPT_DIR/repair-grid-statistics.sh"
fi

WATER_META="$(meta_id sensor.watermeter_value_stabil 1266)"
GAS_META="$(meta_id sensor.gasmeter_value_stabil '')"
GAS_COST_META="$(meta_id sensor.gasmeter_value_stabil_cost_2 '')"
[ -n "$GAS_COST_META" ] || GAS_COST_META="$(meta_id sensor.gasmeter_value_stabil_cost 1278)"

echo ""
echo "========== Wasser (stabil, meta $WATER_META) =========="
. "$SCRIPT_DIR/energie-preise.sh"
WATER_PRICE="$WATER_PRICE" META_ID_VALUE="$WATER_META" META_ID_COST=1268 \
  sh "$SCRIPT_DIR/repair-watermeter-statistics.sh"

if [ -n "$GAS_META" ]; then
  echo ""
  echo "========== Gas (stabil, meta $GAS_META) =========="
  GAS_PRICE="$GAS_PRICE" META_ID_VALUE="$GAS_META" META_ID_COST="$GAS_COST_META" \
    sh "$SCRIPT_DIR/repair-gasmeter-statistics.sh"
fi

echo ""
echo "========== Helios Lüftung (Powercalc-Reset) =========="
sh "$SCRIPT_DIR/repair-helios-energy-statistics.sh" || true

echo ""
echo "========== Kosten aller Medien =========="
sh "$SCRIPT_DIR/sync-energie-cost-all.sh"

echo ""
echo "========== Diagnose (nachher) =========="
sh "$SCRIPT_DIR/check-energie-statistik.sh" || true

echo ""
echo "Fertig. Energie-Dashboard im Browser mit Strg+F5 neu laden."
