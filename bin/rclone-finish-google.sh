#!/bin/sh
# OAuth-Token von "rclone authorize" in /config/rclone.conf schreiben und Remote testen.
set -eu
TOKEN="${1:-}"
if [ -z "$TOKEN" ]; then
  echo "Usage: $0 '<token-json-from-rclone-authorize>'"
  echo ""
  echo "Auf PC mit Browser ausführen:"
  echo '  rclone authorize "drive" "eyJ1c2VfdHJhc2giOiJmYWxzZSJ9"'
  echo "Dann den ausgegebenen JSON-Block als Argument übergeben."
  exit 1
fi
RCLONE=/config/bin/rclone
CONF=/config/rclone.conf
export RCLONE_CONFIG="$CONF"
# Config fortsetzen (Remote-Name: google)
RESULT=$("$RCLONE" config create --continue \
  --state '*oauth-authorize,teamdrive,,' \
  --result "$TOKEN" \
  google drive config_is_local=false use_trash=false 2>&1) || true
echo "$RESULT"
# Falls noch Fragen offen: Team Drive = No
if echo "$RESULT" | grep -q '"State"'; then
  STATE=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('State',''))" 2>/dev/null || true)
  if [ -n "$STATE" ] && [ "$STATE" != "null" ]; then
    RESULT2=$("$RCLONE" config create --continue --state "$STATE" --result "" google drive 2>&1) || true
    echo "$RESULT2"
  fi
fi
echo "--- rclone.conf ---"
grep -A5 '^\[google\]' "$CONF" 2>/dev/null || echo "WARN: [google] noch nicht in rclone.conf"
echo "--- Test ---"
"$RCLONE" lsd google: 2>&1 | head -5
