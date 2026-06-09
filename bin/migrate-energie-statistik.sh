#!/bin/sh
# Einmalige Migration: Roh-Strom bereinigen → Stabil seeden → Kosten sync.
# Gas/Wasser-Stabil nur reparieren wenn nötig. Kein täglicher Seed.

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

export DB_HOST DB_USER DB_PASS DB_NAME

echo "========== Diagnose (vor Migration) =========="
sh "$SCRIPT_DIR/check-energie-statistik.sh" || true

echo ""
echo "========== Strom Roh reparieren (475/476) =========="
sh "$SCRIPT_DIR/repair-grid-statistics.sh"

echo ""
echo "========== Strom → Stabil seeden =========="
sh "$SCRIPT_DIR/seed-mt691-stabil-statistics.sh"

echo ""
echo "========== Wasser stabil reparieren =========="
WATER_META="$(mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N \
  -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.watermeter_value_stabil' LIMIT 1;" 2>/dev/null || echo 1266)"
. "$SCRIPT_DIR/energie-preise.sh"
WATER_PRICE="$WATER_PRICE" META_ID_VALUE="$WATER_META" META_ID_COST=1268 \
  sh "$SCRIPT_DIR/repair-watermeter-statistics.sh"

echo ""
echo "========== Gas stabil reparieren (nur stabil, kein Roh-Seed) =========="
GAS_META="$(mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N \
  -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil' LIMIT 1;" 2>/dev/null || true)"
if [ -n "$GAS_META" ]; then
  GAS_COST_META="$(mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N \
    -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil_cost_2' LIMIT 1;" 2>/dev/null || true)"
  [ -n "$GAS_COST_META" ] || GAS_COST_META="$(mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N \
    -e "SELECT id FROM statistics_meta WHERE statistic_id='sensor.gasmeter_value_stabil_cost' LIMIT 1;" 2>/dev/null || echo 1278)"
  GAS_PRICE="$GAS_PRICE" META_ID_VALUE="$GAS_META" META_ID_COST="$GAS_COST_META" \
    sh "$SCRIPT_DIR/repair-gasmeter-statistics.sh"
fi

echo ""
echo "========== Kosten aller Medien =========="
sh "$SCRIPT_DIR/sync-energie-cost-all.sh"

echo ""
echo "========== Diagnose (nach Migration) =========="
sh "$SCRIPT_DIR/check-energie-statistik.sh" || true

echo ""
echo "Migration abgeschlossen."
echo "Nutzer: Einstellungen → Energie → Netz auf mt691_*_stabil + Preis-Helfer umstellen, dann Strg+F5."
