#!/bin/sh
# Liest Energie-Preise aus HA (input_number) — Fallback auf initial-Werte.
# Nutzung: . /config/bin/energie-preise.sh

set -eu

DB_HOST="${DB_HOST:-core-mariadb}"
DB_USER="${DB_USER:-homeassistant}"
DB_NAME="${DB_NAME:-homeassistant}"

_ha_price() {
  entity="$1"
  fallback="$2"
  val=""

  if command -v ha >/dev/null 2>&1; then
    val="$(ha states get "$entity" --raw-field state 2>/dev/null || true)"
  fi

  if [ -z "$val" ] || [ "$val" = "unknown" ] || [ "$val" = "unavailable" ]; then
    if [ -n "${DB_PASS:-}" ]; then
      val="$(mariadb --ssl=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e \
        "SELECT s.state FROM states s
         JOIN states_meta sm ON s.metadata_id = sm.metadata_id
         WHERE sm.entity_id='$entity' LIMIT 1;" 2>/dev/null || true)"
    fi
  fi

  case "$val" in
    ''|unknown|unavailable|none|NULL) echo "$fallback" ;;
    *) echo "$val" ;;
  esac
}

GAS_PRICE="$(_ha_price input_number.gaspreis_pro_m3 1.32)"
WATER_PRICE="$(_ha_price input_number.wasserpreis_pro_m3 3.52)"
GRID_IMPORT_PRICE="$(_ha_price input_number.strompreis_pro_kwh 0.33376)"
GRID_EXPORT_PRICE="$(_ha_price input_number.einspeiseverguetung_pro_kwh 0.23)"

export GAS_PRICE WATER_PRICE GRID_IMPORT_PRICE GRID_EXPORT_PRICE
