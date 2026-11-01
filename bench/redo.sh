#!/usr/bin/env bash
# Re-runs one arm from a given step: rewinds the arm's branch to the commit before that step
# and drops that arm's records for this step and every later one (raw files are moved to
# results/_discarded/). Then run ./bench/run.sh again: only the dropped steps are executed.
# Usage: ./bench/redo.sh caveman 04            (RUN=2 ./bench/redo.sh ... for run 2)
set -euo pipefail
ARM="${1:?arm, e.g. caveman}"; FROM="${2:?step prefix, e.g. 04}"
RUN="${RUN:-1}"
ROOT=$(git rev-parse --show-toplevel)
WT_DIR="${WT_DIR:-$(dirname "$ROOT")/$(basename "$ROOT")-wt}"
br=$ARM; [ "$RUN" = 1 ] || br="$ARM-r$RUN"
wt="$WT_DIR/$br"; OUT="$ROOT/results/run-$RUN"

# Commit to rewind to: the last commit whose step sorts before FROM.
target=""
for c in $(git -C "$wt" rev-list --reverse "setup/$ARM..$br"); do
  step=$(git -C "$wt" log -1 --format=%s "$c" | cut -d' ' -f1)
  [[ "$step" < "$FROM" ]] && target=$c
done
target=${target:-setup/$ARM}

python3 - "$OUT/steps.jsonl" "$ARM" "$FROM" <<'PY'
import json, sys
log, arm, frm = sys.argv[1:]
rows = [json.loads(l) for l in open(log) if l.strip()]
keep = [r for r in rows if not (r["arm"] == arm and r["step"] >= frm)]
print(f"• dropping {len(rows) - len(keep)} {arm} record(s) from step {frm} on")
open(log, "w").write("".join(json.dumps(r) + "\n" for r in keep))
PY
dest="$ROOT/results/_discarded/run-$RUN-$ARM-from-$FROM-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dest"
for d in raw tests; do
  for f in "$OUT/$d/$ARM"/*; do
    n=$(basename "$f"); [[ -f "$f" && "$n" > "$FROM" || "$n" == "$FROM"* ]] && mv "$f" "$dest/" || true
  done
done
git -C "$wt" reset -q --hard "$target" && git -C "$wt" clean -fdq
echo "• $br rewound to $(git -C "$wt" log -1 --format='%h %s' HEAD)"
echo "Now run: ./bench/run.sh"
