#!/bin/sh
# Synchronisiert Kosten-Statistik für Strom/Gas/Wasser aus Verbrauchs-sum × Preis-Helfer.

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_PASS="${DB_PASS:?DB_PASS required}"
DB_NAME="${DB_NAME:-homeassistant}"

export DB_HOST DB_USER DB_PASS DB_NAME

sh "$SCRIPT_DIR/ensure-mt691-stabil-cost-meta.sh" 2>/dev/null || true

. "$SCRIPT_DIR/energie-preise.sh"

mariadb_cmd() {
  mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" "$@"
}

meta_id() {
  statistic_id="$1"
  mariadb_cmd -N -e "SELECT id FROM statistics_meta WHERE statistic_id='$statistic_id' LIMIT 1;" 2>/dev/null || true
}

cost_meta_for_value() {
  value_stat="$1"
  id=""
  case "$value_stat" in
    sensor.mt691_total_in_stabil)
      id="$(meta_id sensor.strom_bezug_stabil_kosten)"
      [ -n "$id" ] || id="$(meta_id sensor.mt691_total_in_stabil_cost)"
      ;;
    sensor.mt691_total_out_stabil)
      id="$(meta_id sensor.strom_einspeisung_stabil_vergutung)"
      [ -n "$id" ] || id="$(meta_id sensor.mt691_total_out_stabil_compensation)"
      ;;
    sensor.gasmeter_value_stabil)
      id="$(meta_id sensor.gasmeter_stabil_kosten)"
      [ -n "$id" ] || id="$(meta_id sensor.gasmeter_value_stabil_cost_2)"
      [ -n "$id" ] || id="$(meta_id sensor.gasmeter_value_stabil_cost)"
      ;;
    sensor.tasmota_mt691_total_in)
      id="$(meta_id sensor.tasmota_mt691_total_in_cost)"
      ;;
    sensor.tasmota_mt691_total_out)
      id="$(meta_id sensor.tasmota_mt691_total_out_compensation)"
      ;;
    sensor.watermeter_value_stabil)
      id="$(meta_id sensor.watermeter_stabil_kosten)"
      [ -n "$id" ] || id="$(meta_id sensor.watermeter_value_stabil_cost)"
      ;;
    *)
      id="$(meta_id "${value_stat}_cost")"
      ;;
  esac
  echo "$id"
}

sync_pair() {
  value_stat="$1"
  price="$2"
  label="$3"

  val_meta="$(meta_id "$value_stat")"
  cost_meta="$(cost_meta_for_value "$value_stat")"

  [ -n "$val_meta" ] || { echo "Überspringe $label: keine Meta für $value_stat" >&2; return 0; }
  [ -n "$cost_meta" ] || { echo "Überspringe $label: keine Kosten-Meta für $value_stat" >&2; return 0; }

  echo "=== Kosten $label ($value_stat meta $val_meta → cost $cost_meta, Preis $price) ==="
  GAS_PRICE="$price" META_ID_VALUE="$val_meta" META_ID_COST="$cost_meta" \
    sh "$SCRIPT_DIR/sync-gasmeter-cost.sh"
}

# Strom: bevorzugt stabil, Fallback Roh (Migration)
IN_STAT="sensor.mt691_total_in_stabil"
OUT_STAT="sensor.mt691_total_out_stabil"
[ -n "$(meta_id "$IN_STAT")" ] || IN_STAT="sensor.tasmota_mt691_total_in"
[ -n "$(meta_id "$OUT_STAT")" ] || OUT_STAT="sensor.tasmota_mt691_total_out"

sync_pair "$IN_STAT" "$GRID_IMPORT_PRICE" "Strom Bezug"
sync_pair "$OUT_STAT" "$GRID_EXPORT_PRICE" "Strom Einspeisung"
sync_pair "sensor.gasmeter_value_stabil" "$GAS_PRICE" "Gas"
sync_pair "sensor.watermeter_value_stabil" "$WATER_PRICE" "Wasser"

echo "Kosten-Sync aller Medien abgeschlossen."
