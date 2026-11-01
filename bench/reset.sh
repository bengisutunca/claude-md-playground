#!/usr/bin/env bash
# Discards a benchmark run: moves its results aside and rewinds the arm branches to their
# setup commits, so the run can start again from a clean state.
# Usage: ./bench/reset.sh            # run 1 (branches baseline, caveman)
#        RUN=2 ./bench/reset.sh      # run 2 (branches baseline-r2, caveman-r2)
set -euo pipefail
RUN="${RUN:-1}"
ARMS=(baseline caveman)
ROOT=$(git rev-parse --show-toplevel)
WT_DIR="${WT_DIR:-$(dirname "$ROOT")/$(basename "$ROOT")-wt}"

if [ -d "$ROOT/results/run-$RUN" ]; then
  mkdir -p "$ROOT/results/_discarded"
  dest="$ROOT/results/_discarded/run-$RUN-$(date +%Y%m%d-%H%M%S)"
  mv "$ROOT/results/run-$RUN" "$dest"
  echo "• results/run-$RUN moved to ${dest#$ROOT/}"
fi
for arm in "${ARMS[@]}"; do
  br=$arm; [ "$RUN" = 1 ] || br="$arm-r$RUN"
  if [ -d "$WT_DIR/$br" ]; then
    git -C "$WT_DIR/$br" reset -q --hard "setup/$arm"
    git -C "$WT_DIR/$br" clean -fdq
    echo "• $br rewound to setup/$arm"
  fi
done
rm -f "$ROOT/results/RESULTS.md"
echo "Done. Start again with: ./bench/run.sh"
