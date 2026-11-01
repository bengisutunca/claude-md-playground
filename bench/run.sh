#!/usr/bin/env bash
# Runs the benchmark on macOS. Each task in bench/tasks/ is given, word for word, to a fresh
# headless Claude Code session on every arm. After each step the harness runs the tests,
# commits the result on the arm's branch and records cost/tokens from Claude's JSON output.
#
# Usage:   ./bench/run.sh                 # run 1 on branches `baseline` and `caveman`
#          RUN=2 ./bench/run.sh           # repeat on fresh branches `baseline-r2`, `caveman-r2`
#          MODEL=opus ./bench/run.sh      # default model: sonnet
#          ONLY=03 ./bench/run.sh         # only steps whose file name starts with 03
# Safe to re-run: steps already recorded for this run are skipped (resume after interruption).
set -euo pipefail

RUN="${RUN:-1}"
MODEL="${MODEL:-sonnet}"
MAX_TURNS="${MAX_TURNS:-80}"
ONLY="${ONLY:-}"
ARMS=(baseline caveman)

ROOT=$(git rev-parse --show-toplevel)
WT_DIR="${WT_DIR:-$(dirname "$ROOT")/$(basename "$ROOT")-wt}"
OUT="$ROOT/results/run-$RUN"
LOG="$OUT/steps.jsonl"
mkdir -p "$OUT"
touch "$LOG"

# ---------- preflight ----------
for bin in claude swift git python3; do
  command -v "$bin" >/dev/null || { echo "✗ '$bin' not found in PATH"; exit 1; }
done
[ -n "${ANTHROPIC_API_KEY:-}" ] && echo "ℹ ANTHROPIC_API_KEY is set: runs are billed to the API key."
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  echo "⚠ $HOME/.claude/CLAUDE.md exists. It is loaded in BOTH arms and adds noise."
  echo "  Rename it for the duration of the benchmark, or press Enter to continue anyway."
  read -r _
fi
if command -v caveman >/dev/null || ls "$HOME/.claude/plugins" 2>/dev/null | grep -qi caveman; then
  echo "⚠ A caveman install was detected on this machine (CLI or Claude Code plugin)."
  echo "  It would affect BOTH arms. Disable it (caveman off / uninstall) or press Enter to continue."
  read -r _
fi

EXTRA_FLAGS=()
HELP=$(claude --help 2>&1 || true)
# Load only the repo's own settings, so user-level plugins/hooks do not leak into either arm.
grep -q -- '--setting-sources' <<<"$HELP" && EXTRA_FLAGS+=(--setting-sources project,local)
grep -q -- '--strict-mcp-config' <<<"$HELP" && EXTRA_FLAGS+=(--strict-mcp-config)

# ---------- worktrees ----------
branch_for() { [ "$RUN" = 1 ] && echo "$1" || echo "$1-r$RUN"; }
for arm in "${ARMS[@]}"; do
  br=$(branch_for "$arm")
  git -C "$ROOT" rev-parse --verify -q "refs/tags/setup/$arm" >/dev/null \
    || { echo "✗ Missing tag setup/$arm. Run ./bench/setup.sh first."; exit 1; }
  git -C "$ROOT" rev-parse --verify -q "$br" >/dev/null || git -C "$ROOT" branch "$br" "setup/$arm"
  [ -d "$WT_DIR/$br" ] || git -C "$ROOT" worktree add -q "$WT_DIR/$br" "$br"
done

done_already() { # arm step
  python3 - "$LOG" "$1" "$2" <<'PY'
import json, sys
log, arm, step = sys.argv[1:]
for line in open(log):
    line = line.strip()
    if line and (r := json.loads(line))["arm"] == arm and r["step"] == step:
        sys.exit(0)
sys.exit(1)
PY
}

# ---------- main loop ----------
echo "Run $RUN · model $MODEL · flags: ${EXTRA_FLAGS[*]:-none}"
i=0
for task in "$ROOT"/bench/tasks/*.md; do
  step=$(basename "$task" .md)
  [[ -n "$ONLY" && "$step" != "$ONLY"* ]] && continue
  # Alternate arm order per step so neither arm always runs first (cache/time-of-day effects).
  if (( i % 2 == 0 )); then order=("${ARMS[@]}"); else order=("${ARMS[1]}" "${ARMS[0]}"); fi
  i=$((i + 1))

  for arm in "${order[@]}"; do
    br=$(branch_for "$arm"); wt="$WT_DIR/$br"
    if done_already "$arm" "$step"; then echo "• $arm / $step already recorded, skipping"; continue; fi
    mkdir -p "$OUT/raw/$arm" "$OUT/tests/$arm"
    raw="$OUT/raw/$arm/$step.json"; testlog="$OUT/tests/$arm/$step.log"

    echo "▶ [$arm] $step"
    cd "$wt"
    git reset -q --hard && git clean -fdq

    start=$(date +%s)
    set +e
    claude -p "$(cat "$task")" \
      --model "$MODEL" \
      --output-format json \
      --max-turns "$MAX_TURNS" \
      ${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"} \
      > "$raw" 2> "$OUT/raw/$arm/$step.stderr"
    claude_exit=$?
    swift build > "$testlog" 2>&1 && swift test >> "$testlog" 2>&1
    test_exit=$?
    set -e
    wall=$(( $(date +%s) - start ))

    git add -A
    git commit -q --allow-empty -m "$step ($arm, run $RUN)" \
      -m "tests: $([ $test_exit = 0 ] && echo pass || echo FAIL) · model: $MODEL"
    sha=$(git rev-parse --short HEAD)
    files_changed=$(git show --shortstat --format= HEAD | tr -s ' ')

    python3 - "$raw" "$LOG" "$arm" "$step" "$RUN" "$MODEL" "$claude_exit" "$test_exit" "$wall" "$sha" "$files_changed" <<'PY'
import json, sys
raw, log, arm, step, run, model, cexit, texit, wall, sha, diff = sys.argv[1:]
try:
    d = json.load(open(raw))
except Exception:
    d = {}
u = d.get("usage") or {}
rec = {
    "run": int(run), "arm": arm, "step": step, "model": model, "commit": sha,
    "cost_usd": d.get("total_cost_usd"),
    "turns": d.get("num_turns"),
    "duration_ms": d.get("duration_ms"),
    "wall_s": int(wall),
    "input_tokens": u.get("input_tokens"),
    "cache_write_tokens": u.get("cache_creation_input_tokens"),
    "cache_read_tokens": u.get("cache_read_input_tokens"),
    "output_tokens": u.get("output_tokens"),
    "is_error": d.get("is_error", True) or cexit != "0",
    "subtype": d.get("subtype"),
    "tests_pass": texit == "0",
    "diff": diff.strip(),
}
open(log, "a").write(json.dumps(rec) + "\n")
c = rec["cost_usd"]
print(f"  cost ${c:.4f}" if c is not None else "  cost n/a", "· turns", rec["turns"],
      "· out", rec["output_tokens"], "· tests", "pass" if rec["tests_pass"] else "FAIL")
PY
    cd "$ROOT"
  done
done

echo
python3 "$ROOT/bench/summarize.py"
