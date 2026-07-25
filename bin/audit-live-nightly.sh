#!/usr/bin/env bash
# Nächtlicher Voll-Live-Audit: alle 12 Module (--quick), Summary-Report
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE_JSON="$ROOT/manifests/live-audit-state.json"
LOCK_FILE="$ROOT/log/live-audit-nightly.lock"
LOG_FILE="$ROOT/log/live-audit-nightly.log"
REPORT_DIR="$ROOT/log/live-audit"

QUICK=true
for arg in "$@"; do
  case "$arg" in
    --full) QUICK=false ;;
    -h|--help)
      cat <<EOF
Usage: audit-live-nightly.sh [--full]

  Standard: T0+T1 für alle Module (--quick).
  --full:   inkl. Tier-2-Domain-Skripte (länger, z. B. Energie/HACS).
EOF
      exit 0
      ;;
    *)
      echo "Unbekanntes Argument: $arg" >&2
      exit 1
      ;;
  esac
done

mkdir -p "$ROOT/log" "$REPORT_DIR"

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "$(date -Iseconds) Übersprungen — vorheriger Nightly-Lauf aktiv?" | tee -a "$LOG_FILE"
  exit 0
fi

log() {
  echo "$@" | tee -a "$LOG_FILE"
}

RUN_ID="$(date -Iseconds)"
SUMMARY_JSON="$REPORT_DIR/nightly-${RUN_ID//:/}.json"
SUMMARY_MD="$REPORT_DIR/nightly-${RUN_ID//:/}.md"
LATEST_MD="$REPORT_DIR/nightly-latest.md"
LATEST_JSON="$REPORT_DIR/nightly-latest.json"

MODULES="$(python3 -c "import json; print(' '.join(json.load(open('$STATE_JSON'))['module_order']))")"

log "=== Live-Audit Nightly $RUN_ID (quick=$QUICK) ==="

for m in $MODULES; do
  log "--- Modul: $m ---"
  ARGS=(--module "$m")
  $QUICK && ARGS+=(--quick)
  set +e
  "$ROOT/bin/audit-live.sh" "${ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"
  set -e
done

QUICK_PY="True"
$QUICK || QUICK_PY="False"

python3 - <<PY
import json
from pathlib import Path

root = Path("$ROOT")
state = json.loads((root / "manifests/live-audit-state.json").read_text())
run_id = "$RUN_ID"
quick = $QUICK_PY

modules = []
fail_total = warn_total = info_total = 0

for mid in state.get("module_order", []):
    mod = state.get("modules", {}).get(mid, {})
    report_path = mod.get("last_report")
    status = mod.get("status", "?")
    fc = wc = ic = 0
    if report_path and Path(report_path).is_file():
        report = json.loads(Path(report_path).read_text())
        status = report.get("status", status)
        for f in report.get("findings", []):
            sev = f.get("severity")
            if sev == "fail":
                fc += 1
            elif sev == "warn":
                wc += 1
            elif sev == "info":
                ic += 1
    fail_total += fc
    warn_total += wc
    info_total += ic
    modules.append({"id": mid, "status": status, "fail": fc, "warn": wc, "info": ic})

if fail_total > 0:
    overall = "fail"
elif warn_total > 0:
    overall = "warn"
else:
    overall = "ok"

summary = {
    "run_id": run_id,
    "type": "nightly",
    "overall_status": overall,
    "quick": quick,
    "totals": {"fail": fail_total, "warn": warn_total, "info": info_total},
    "modules": modules,
}

summary_json = Path("$SUMMARY_JSON")
summary_md = Path("$SUMMARY_MD")
summary_json.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

lines = [
    "# Live-Audit Nightly",
    "",
    f"- **Run:** {run_id}",
    f"- **Gesamt:** **{overall.upper()}**",
    f"- **Quick:** {quick}",
    f"- **Findings:** fail={fail_total} warn={warn_total} info={info_total}",
    "",
    "| Modul | Status | fail | warn | info |",
    "|-------|--------|-----:|-----:|-----:|",
]
for m in modules:
    lines.append(f"| {m['id']} | {m['status']} | {m['fail']} | {m['warn']} | {m['info']} |")
lines.append("")
summary_md.write_text("\n".join(lines), encoding="utf-8")

Path("$LATEST_JSON").write_text(summary_json.read_text(encoding="utf-8"), encoding="utf-8")
Path("$LATEST_MD").write_text(summary_md.read_text(encoding="utf-8"), encoding="utf-8")

print(f"overall={overall} fail={fail_total} warn={warn_total} info={info_total}")
print(summary_md)
PY

log "Fertig — Summary: $SUMMARY_MD"
echo ""
cat "$SUMMARY_MD"
