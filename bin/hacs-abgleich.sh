#!/usr/bin/env bash
# HACS-Inventar exportieren und bei Änderungen committen (optional pushen)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUSH=false
LOCK_FILE="$ROOT/log/hacs-abgleich.lock"

for arg in "$@"; do
  case "$arg" in
    --push) PUSH=true ;;
    -h|--help)
      echo "Usage: hacs-abgleich.sh [--push]"
      echo "  Exportiert HACS-Inventar; committet nur bei Git-Änderungen."
      exit 0
      ;;
    *)
      echo "Unbekanntes Argument: $arg" >&2
      exit 1
      ;;
  esac
done

cd "$ROOT"
mkdir -p log

# Cron: SSH-Key und Timeout — verhindert Hänger bei fehlendem Agent/Passphrase-Prompt
export HOME="${HOME:-/root}"
if [[ -f "$ROOT/.ssh/id_rsa" ]]; then
  export GIT_SSH_COMMAND="ssh -i $ROOT/.ssh/id_rsa -o BatchMode=yes -o ConnectTimeout=20 -o StrictHostKeyChecking=accept-new"
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "$(date -Iseconds) Übersprungen — vorheriger Lauf noch aktiv?" >> "$ROOT/log/hacs-abgleich.log"
  exit 0
fi

log() {
  echo "$@" | tee -a "$ROOT/log/hacs-abgleich.log"
}

log "=== $(date -Iseconds) hacs-abgleich ==="
"$ROOT/bin/export-hacs-inventar.sh" 2>&1 | tee -a "$ROOT/log/hacs-abgleich.log"

if git diff --quiet -- manifests/hacs-inventar.json docs/hacs-inventar.md; then
  log "Keine Änderungen — kein Commit."
  exit 0
fi

git add manifests/hacs-inventar.json docs/hacs-inventar.md
git commit -m "$(cat <<EOF
chore: HACS-Inventar Abgleich $(date +%Y-%m-%d)

Automatischer Snapshot installierter HACS-Komponenten.
EOF
)"
log "Commit erstellt."

if $PUSH; then
  if timeout 90 git push origin HEAD 2>&1 | tee -a "$ROOT/log/hacs-abgleich.log"; then
    log "Push abgeschlossen."
  else
    log "Push fehlgeschlagen (Timeout oder SSH) — Commit liegt lokal."
    exit 1
  fi
fi
