#!/usr/bin/env bash
# Live-Audit Orchestrator: modular Repo ↔ HA verification
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULES_JSON="$ROOT/manifests/live-audit-modules.json"
STATE_JSON="$ROOT/manifests/live-audit-state.json"
LOCK_FILE="$ROOT/log/live-audit.lock"
REPORT_DIR="$ROOT/log/live-audit"
TMP_DIR="$ROOT/log/live-audit/tmp"

MODULE=""
RESUME=false
QUICK=false
RESET_CYCLE=false
RUN_T0=true

usage() {
  cat <<EOF
Usage: audit-live.sh [--module ID] [--resume] [--quick] [--reset-cycle] [--no-t0]

  --module ID     Audit single module (core, haushalt, …)
  --resume        Run next pending module from state manifest
  --quick         T0+T1 only (skip tier2 scripts)
  --reset-cycle   Reset all modules to pending
  --no-t0         Skip T0 log/core check (T1 only)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --module) MODULE="$2"; shift 2 ;;
    --resume) RESUME=true; shift ;;
    --quick) QUICK=true; shift ;;
    --reset-cycle) RESET_CYCLE=true; shift ;;
    --no-t0) RUN_T0=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unbekanntes Argument: $1" >&2; usage; exit 1 ;;
  esac
done

mkdir -p "$REPORT_DIR" "$TMP_DIR"

if $RESET_CYCLE; then
  python3 "$ROOT/bin/audit-live-state.py" --reset --state "$STATE_JSON"
  echo "Zyklus zurückgesetzt: $STATE_JSON"
  exit 0
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "$(date -Iseconds) Übersprungen — vorheriger Audit-Lauf aktiv?" >&2
  exit 0
fi

if $RESUME; then
  MODULE="$(python3 "$ROOT/bin/audit-live-state.py" --next --state "$STATE_JSON")"
  if [[ -z "$MODULE" || "$MODULE" == "COMPLETE" ]]; then
    echo "Zyklus complete — kein pending Modul. Nutze --reset-cycle für neuen Durchlauf."
    exit 0
  fi
fi

if [[ -z "$MODULE" ]]; then
  echo "Fehler: --module ID oder --resume erforderlich" >&2
  usage
  exit 1
fi

RUN_ID="$(date -Iseconds)"
REPORT_JSON="$REPORT_DIR/${RUN_ID//:/}-${MODULE}.json"
REPORT_MD="$REPORT_DIR/${RUN_ID//:/}-${MODULE}.md"
ENTITIES_JSON="$TMP_DIR/${MODULE}-entities.json"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$REPORT_DIR/audit-live.log"; }

log "=== Live-Audit Modul: $MODULE ==="

# Load module config from YAML via Python
MOD_CFG="$(python3 "$ROOT/bin/audit-live-modules.py" --get "$MODULE" --manifest "$MODULES_JSON")"
if [[ -z "$MOD_CFG" || "$MOD_CFG" == "null" ]]; then
  echo "Unbekanntes Modul: $MODULE" >&2
  exit 1
fi

SPECS="$(python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join(d.get('specs',[])))" <<<"$MOD_CFG")"
YAML_PATHS="$(python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join(d.get('yaml_paths',[])))" <<<"$MOD_CFG")"
KNOWN_ISSUES="$(python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('known_issues',[])))" <<<"$MOD_CFG")"
MODULE_TITLE="$(python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title', sys.argv[1]))" "$MODULE" <<<"$MOD_CFG")"

ALL_FINDINGS_JSON="$TMP_DIR/${MODULE}-all-findings.json"
echo "[]" > "$ALL_FINDINGS_JSON"
TIER_COMPLETED=0
OVERALL_STATUS="ok"

merge_findings() {
  local tier_json="$1"
  python3 - <<PY
import json
from pathlib import Path
a = json.loads(Path("$ALL_FINDINGS_JSON").read_text())
b = json.loads(Path("$tier_json").read_text())
a.extend(b.get("findings", []))
Path("$ALL_FINDINGS_JSON").write_text(json.dumps(a, ensure_ascii=False))
PY
  local st
  st="$(python3 -c "import json; d=json.load(open('$tier_json')); print(d.get('status','ok'))")"
  if [[ "$st" == "fail" ]]; then OVERALL_STATUS="fail"
  elif [[ "$st" == "warn" && "$OVERALL_STATUS" != "fail" ]]; then OVERALL_STATUS="warn"
  fi
}

# T0
T0_JSON="$TMP_DIR/${MODULE}-t0.json"
if $RUN_T0; then
  log "T0: core check + logs"
  python3 "$ROOT/bin/audit-check-logs.py" > "$T0_JSON"
  merge_findings "$T0_JSON"
  TIER_COMPLETED=0
fi

# T1 — entity extraction + registry check
log "T1: Entity-Abgleich"
EXTRACT_ARGS=(python3 "$ROOT/bin/audit-extract-entities.py" --root "$ROOT" --json)
for spec in $SPECS; do EXTRACT_ARGS+=(--spec "$spec"); done
for yp in $YAML_PATHS; do EXTRACT_ARGS+=(--yaml "$yp"); done
"${EXTRACT_ARGS[@]}" > "$ENTITIES_JSON"

T1_JSON="$TMP_DIR/${MODULE}-t1.json"
CHECK_CE=false
[[ "$MODULE" == "integrations" || "$MODULE" == "core" ]] && CHECK_CE=true

python3 "$ROOT/bin/audit-check-registry.py" \
  --root "$ROOT" \
  --entities-json "$ENTITIES_JSON" \
  --known-issues "$KNOWN_ISSUES" \
  $([[ "$CHECK_CE" == true ]] && echo --check-config-entries) \
  --json > "$T1_JSON"

merge_findings "$T1_JSON"
TIER_COMPLETED=1

STATS="$(python3 -c "import json; d=json.load(open('$T1_JSON')); print(json.dumps(d.get('stats',{})))")"

# T2 — optional domain script
if ! $QUICK; then
  T2_SCRIPT="$(python3 -c "import json,sys; d=json.load(sys.stdin); s=d.get('tier2_script'); print(s if s else '')" <<<"$MOD_CFG")"
  if [[ -n "$T2_SCRIPT" && -x "$ROOT/$T2_SCRIPT" ]]; then
    log "T2: $T2_SCRIPT"
    T2_JSON="$TMP_DIR/${MODULE}-t2.json"
    T2_OUT="$TMP_DIR/${MODULE}-t2.out"
    set +e
    if [[ "$T2_SCRIPT" == "bin/export-hacs-inventar.sh" ]]; then
      "$ROOT/$T2_SCRIPT" > "$T2_OUT" 2>&1
      T2_RC=$?
      python3 - <<PY > "$T2_JSON"
import json
out = open("$T2_OUT").read()
findings = []
if $T2_RC != 0:
    findings.append({"severity":"warn","code":"TIER2_SCRIPT_FAIL","entity":None,"message":"export-hacs-inventar.sh exit $T2_RC"})
else:
    findings.append({"severity":"info","code":"TIER2_HACS_EXPORT","entity":None,"message":"HACS-Inventar exportiert — Diff manuell gegen docs/hacs-inventar.md prüfen"})
print(json.dumps({"status":"ok" if not findings or all(f["severity"]=="info" for f in findings) else "warn","findings":findings}, ensure_ascii=False, indent=2))
PY
    else
      DB_PASS="$(python3 -c "
import re
text=open('$ROOT/secrets.yaml').read()
m=re.search(r'^maria_db_recorder_db_url:\\s*mysql://[^:]+:([^@]+)@', text, re.M)
print(m.group(1) if m else '')
" 2>/dev/null || true)"
      if [[ -n "$DB_PASS" ]]; then
        DB_PASS="$DB_PASS" "$ROOT/$T2_SCRIPT" > "$T2_OUT" 2>&1
      else
        "$ROOT/$T2_SCRIPT" > "$T2_OUT" 2>&1
      fi
      T2_RC=$?
      python3 - <<PY > "$T2_JSON"
import json
out = open("$T2_OUT").read()[-2000:]
findings = []
if $T2_RC != 0:
    findings.append({"severity":"warn","code":"TIER2_SCRIPT_FAIL","entity":None,"message":"$T2_SCRIPT exit $T2_RC"})
else:
    if "Auffällige" in out or "Sprung" in out:
        findings.append({"severity":"warn","code":"TIER2_ANOMALY","entity":None,"message":"Domain-Skript meldet Auffälligkeit — siehe Report-Auszug"})
    findings.append({"severity":"info","code":"TIER2_OUTPUT","entity":None,"message":out[-500:] if out else "T2 ok"})
status = "fail" if any(f["severity"]=="fail" for f in findings) else ("warn" if any(f["severity"]=="warn" for f in findings) else "ok")
print(json.dumps({"status":status,"findings":findings}, ensure_ascii=False, indent=2))
PY
    fi
    set -e
    merge_findings "$T2_JSON"
    TIER_COMPLETED=2
  fi
fi

# Final report JSON
python3 - <<PY > "$REPORT_JSON"
import json
from datetime import datetime

findings = json.loads(open("$ALL_FINDINGS_JSON").read())
stats = json.loads('''$STATS''')
report = {
    "run_id": "$RUN_ID",
    "module": "$MODULE",
    "module_title": """$MODULE_TITLE""",
    "tier_completed": $TIER_COMPLETED,
    "status": "$OVERALL_STATUS",
    "findings": findings,
    "stats": stats,
    "entities_file": "$ENTITIES_JSON",
}
print(json.dumps(report, ensure_ascii=False, indent=2))
PY

# Markdown report
python3 "$ROOT/bin/audit-report-md.py" "$REPORT_JSON" > "$REPORT_MD"

# Update state
FINDINGS_COUNT="$(python3 -c "import json; print(len(json.load(open('$REPORT_JSON'))['findings']))")"
python3 "$ROOT/bin/audit-live-state.py" \
  --update \
  --state "$STATE_JSON" \
  --module "$MODULE" \
  --status "$OVERALL_STATUS" \
  --tier "$TIER_COMPLETED" \
  --findings-count "$FINDINGS_COUNT" \
  --report "$REPORT_JSON"

log "Fertig: status=$OVERALL_STATUS findings=$FINDINGS_COUNT"
log "Report: $REPORT_MD"
echo ""
echo "=== Live-Audit: $MODULE ($OVERALL_STATUS) ==="
echo "JSON: $REPORT_JSON"
echo "MD:   $REPORT_MD"
head -40 "$REPORT_MD"
