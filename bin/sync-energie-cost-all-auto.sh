#!/bin/sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SECRETS="${SECRETS:-/config/secrets.yaml}"
DB_PASS="$(sed -n 's|^maria_db_recorder_db_url: mysql://[^:]*:\([^@]*\)@.*|\1|p' "$SECRETS" | head -1)"
[ -n "$DB_PASS" ] || { echo "DB_PASS aus secrets.yaml nicht lesbar" >&2; exit 1; }
export DB_PASS
exec sh "$SCRIPT_DIR/sync-energie-cost-all.sh"
