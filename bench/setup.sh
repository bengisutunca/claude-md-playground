#!/usr/bin/env bash
# Prepares the repo for the benchmark. Run once, from anywhere inside the repo, on macOS.
#   1. Commits the base project on `main` (if main has no commits yet) and tags it `base`.
#   2. Creates one branch per arm from `main`:
#        baseline : app skeleton only, no CLAUDE.md
#        caveman  : app skeleton + CLAUDE.md with the caveman rules
#      The benchmark tooling (bench/, results/) is removed on arm branches so the agent
#      under test only sees the app. Each arm's setup commit is tagged `setup/<arm>`.
#   3. Checks out each arm in a worktree next to the repo: ../claude-md-playground-wt/<arm>
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
WT_DIR="${WT_DIR:-$(dirname "$ROOT")/$(basename "$ROOT")-wt}"
ARMS=(baseline caveman)
cd "$ROOT"

# Shared tool permissions for both arms (kept in bench/ and installed here).
if [ ! -f .claude/settings.json ]; then
  mkdir -p .claude
  cp bench/claude-settings.json .claude/settings.json
fi

if ! git rev-parse --verify -q main >/dev/null; then
  echo "▶ Committing base project on main"
  git add -A
  git commit -q -m "Base project: MVVM skeleton, TMDB fixtures, benchmark harness"
fi
git rev-parse -q --verify refs/tags/base >/dev/null || git tag base main

mkdir -p "$WT_DIR"
for arm in "${ARMS[@]}"; do
  if git rev-parse --verify -q "$arm" >/dev/null; then
    echo "• branch $arm already exists, skipping"
  else
    echo "▶ Creating branch $arm"
    git worktree add -q -b "$arm" "$WT_DIR/$arm" main
    (
      cd "$WT_DIR/$arm"
      git rm -r -q bench results
      if [ "$arm" = caveman ]; then
        cp "$ROOT/bench/arms/caveman/CLAUDE.md" CLAUDE.md
        git add CLAUDE.md
      fi
      git commit -q -m "Arm setup: $arm"
    )
    git tag -f "setup/$arm" "$arm" >/dev/null
  fi
  [ -d "$WT_DIR/$arm" ] || git worktree add -q "$WT_DIR/$arm" "$arm"
done

echo
echo "Done. Worktrees:"
git worktree list
echo
echo "Branch contents check:"
for arm in "${ARMS[@]}"; do
  printf '  %-9s CLAUDE.md: %s\n' "$arm" "$([ -f "$WT_DIR/$arm/CLAUDE.md" ] && echo yes || echo no)"
done
