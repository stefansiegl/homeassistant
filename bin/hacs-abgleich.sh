#!/usr/bin/env bash
# HACS-Inventar exportieren und bei Änderungen committen (optional pushen)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUSH=false

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

{
  echo "=== $(date -Iseconds) hacs-abgleich ==="
  "$ROOT/bin/export-hacs-inventar.sh"

  if git diff --quiet -- manifests/hacs-inventar.json docs/hacs-inventar.md; then
    echo "Keine Änderungen — kein Commit."
    exit 0
  fi

  git add manifests/hacs-inventar.json docs/hacs-inventar.md
  git commit -m "$(cat <<EOF
chore: HACS-Inventar Abgleich $(date +%Y-%m-%d)

Automatischer Snapshot installierter HACS-Komponenten.
EOF
)"
  echo "Commit erstellt."

  if $PUSH; then
    git push origin HEAD
    echo "Push abgeschlossen."
  fi
} 2>&1 | tee -a "$ROOT/log/hacs-abgleich.log"
