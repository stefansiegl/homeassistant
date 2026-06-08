#!/bin/sh
# Einheitliche Reparatur aller Energie-Dashboard-Quellen (Strom/Gas/Wasser).
# Nach Entity-Umstellung, Seed, Core-Neustart oder komischen Kosten immer dieses Skript —
# nicht einzelne Medien raten.
#
# Nutzung:
#   DB_PASS='…' /config/bin/repair-energie-dashboard.sh
# Optional: GAS_PRICE=1.32 WATER_PRICE=3.52 (Defaults wie Energie-Dashboard)

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"
GAS_PRICE="${GAS_PRICE:-1.32}"
WATER_PRICE="${WATER_PRICE:-3.52}"

export DB_HOST DB_USER DB_PASS DB_NAME

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

meta_id() {
  statistic_id="$1"
  fallback="$2"
  id="$(mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='$statistic_id' LIMIT 1;" 2>/dev/null || true)"
  if [ -n "$id" ]; then
    echo "$id"
  else
    echo "$fallback"
  fi
}

echo "========== Diagnose (vorher) =========="
sh "$SCRIPT_DIR/check-energie-statistik.sh" || true

echo ""
echo "========== Strom (MT691 Import/Export) =========="
sh "$SCRIPT_DIR/repair-grid-statistics.sh"

echo ""
echo "========== Gas (Roh-Statistik bereinigen) =========="
GAS_PRICE="$GAS_PRICE" META_ID_VALUE=848 META_ID_COST=1080 \
  sh "$SCRIPT_DIR/repair-gasmeter-statistics.sh"

GAS_STABIL_META="$(meta_id sensor.gasmeter_value_stabil '')"
if [ -n "$GAS_STABIL_META" ]; then
  echo ""
  echo "========== Gas (Historie → stabil, meta $GAS_STABIL_META) =========="
  META_DST="$GAS_STABIL_META" sh "$SCRIPT_DIR/seed-gasmeter-stabil-statistics.sh"
fi

WATER_META="$(meta_id sensor.watermeter_value_stabil 1266)"

echo ""
echo "========== Wasser (stabil, meta $WATER_META) =========="
WATER_PRICE="$WATER_PRICE" META_ID_VALUE="$WATER_META" META_ID_COST=1268 \
  sh "$SCRIPT_DIR/repair-watermeter-statistics.sh"

echo ""
echo "========== Helios Lüftung (Powercalc-Reset) =========="
sh "$SCRIPT_DIR/repair-helios-energy-statistics.sh" || true

echo ""
echo "========== Kosten-Statistik entfernen (Dashboard: Verbrauch × Preis) =========="
sh "$SCRIPT_DIR/purge-energie-cost-statistics.sh"

echo ""
echo "========== Diagnose (nachher) =========="
sh "$SCRIPT_DIR/check-energie-statistik.sh" || true

echo ""
echo "Fertig. Energie-Dashboard im Browser mit Strg+F5 neu laden."
