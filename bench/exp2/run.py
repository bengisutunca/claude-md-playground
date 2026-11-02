#!/usr/bin/env python3
"""Experiment 2: checkpoint mode with repeated trials and hidden acceptance tests.

Every task is run K times per arm. Each trial is a fresh headless Claude Code session that
starts from the same reference commit in both arms; the caveman arm only adds CLAUDE.md.
After the session the harness runs the agent's own tests, then the hidden acceptance test
for that task, and stores cost, tokens, the patch and the final answer.

Usage (from the repo root, on macOS):
    python3 bench/exp2/run.py                      # all 14 tasks x 2 arms x 3 trials
    python3 bench/exp2/run.py --trials 1           # quick pass
    python3 bench/exp2/run.py --set code           # code | fix | explain | all
    python3 bench/exp2/run.py --only 04,d1         # task-name prefixes
    python3 bench/exp2/run.py --model opus         # default: sonnet
Safe to re-run: trials already recorded are skipped.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import (ARMS, OUT, PERM_FLAGS, TASK_DIR, TASKS, acceptance_total, ensure_refs,
                    ensure_worktree, git, prepare, read_json_lines, run_acceptance, sh,
                    write_json_line)

LOG = OUT / "trials.jsonl"


def preflight():
    for b in ["claude", "swift", "git"]:
        if not shutil.which(b):
            sys.exit(f"✗ '{b}' not found in PATH")
    home = Path.home()
    if (home / ".claude" / "CLAUDE.md").exists():
        print(f"⚠ {home}/.claude/CLAUDE.md exists and is loaded in BOTH arms. Rename it, or press Enter.")
        input()
    help_text = sh(["claude", "--help"], check=False).stdout
    extra = []
    if "--setting-sources" in help_text:
        extra += ["--setting-sources", "project,local"]
    if "--strict-mcp-config" in help_text:
        extra += ["--strict-mcp-config"]
    return extra


def run_claude(wt, prompt, model, max_turns, extra, raw, stderr_path):
    """Runs one headless session; retries up to 3 times on API/network errors."""
    for attempt in range(1, 4):
        with open(raw, "w") as out, open(stderr_path, "w") as err:
            r = subprocess.run(["claude", "-p", prompt, "--model", model, "--output-format", "json",
                                "--max-turns", str(max_turns), *extra, *PERM_FLAGS],
                               cwd=wt, stdout=out, stderr=err, text=True)
        try:
            d = json.loads(Path(raw).read_text())
        except Exception:
            d = {}
        if d and d.get("terminal_reason") != "api_error" and not d.get("api_error_status"):
            return d, r.returncode
        print(f"    ⚠ API/network error (attempt {attempt}), retrying in 30 s")
        shutil.copy(raw, f"{raw}.attempt{attempt}")
        git("reset", "-q", "--hard", cwd=wt)
        git("clean", "-fdq", cwd=wt)
        time.sleep(30)
    return d, r.returncode


def rubric_score(text, groups):
    t = text.lower()
    hits = sum(any(w.lower() in t for w in g) for g in groups)
    return hits / len(groups)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--trials", type=int, default=int(os.environ.get("TRIALS", 3)))
    ap.add_argument("--set", default="all", choices=["all", "code", "fix", "explain"])
    ap.add_argument("--only", default="")
    ap.add_argument("--model", default=os.environ.get("MODEL", "sonnet"))
    ap.add_argument("--max-turns", type=int, default=80)
    args = ap.parse_args()

    extra = preflight()
    ensure_refs()
    wts = {arm: ensure_worktree(f"exp2-{arm}") for arm in ARMS}
    only = [p.strip() for p in args.only.split(",") if p.strip()]
    tasks = [t for t, c in TASKS.items()
             if (args.set == "all" or c["kind"] == args.set)
             and (not only or any(t.startswith(p) for p in only))]
    done = {(r["task"], r["arm"], r["trial"]) for r in read_json_lines(LOG)}
    todo = len(tasks) * len(ARMS) * args.trials - sum(
        1 for t in tasks for a in ARMS for k in range(1, args.trials + 1) if (t, a, k) in done)
    print(f"Experiment 2 · model {args.model} · {len(tasks)} tasks × {len(ARMS)} arms × "
          f"{args.trials} trials · {todo} sessions to run")

    for trial in range(1, args.trials + 1):
        for i, task in enumerate(tasks):
            cfg = TASKS[task]
            arms = ARMS if (i + trial) % 2 == 0 else ARMS[::-1]  # balance run order
            prompt = (TASK_DIR / f"{task}.md").read_text()
            for arm in arms:
                if (task, arm, trial) in done:
                    continue
                wt = wts[arm]
                base = OUT / "raw" / task
                base.mkdir(parents=True, exist_ok=True)
                stem = base / f"{arm}-t{trial}"
                print(f"▶ trial {trial} · {task} · {arm}")
                prepare(wt, cfg["start"], arm=arm, bug=cfg.get("bug"))

                t0 = time.time()
                d, code = run_claude(wt, prompt, args.model, args.max_turns, extra,
                                     f"{stem}.json", f"{stem}.stderr")
                answer = d.get("result", "") or ""
                Path(f"{stem}.answer.md").write_text(answer)

                git("add", "-A", cwd=wt)
                patch = git("diff", "--cached", "--binary", "HEAD", cwd=wt).stdout
                Path(f"{stem}.patch").write_text(patch)
                stat = git("diff", "--cached", "--shortstat", "HEAD", cwd=wt).stdout.strip()

                rec = {
                    "task": task, "kind": cfg["kind"], "arm": arm, "trial": trial, "model": args.model,
                    "cost_usd": d.get("total_cost_usd"), "turns": d.get("num_turns"),
                    "duration_ms": d.get("duration_ms"), "wall_s": None,
                    "input_tokens": (d.get("usage") or {}).get("input_tokens"),
                    "cache_write_tokens": (d.get("usage") or {}).get("cache_creation_input_tokens"),
                    "cache_read_tokens": (d.get("usage") or {}).get("cache_read_input_tokens"),
                    "output_tokens": (d.get("usage") or {}).get("output_tokens"),
                    "is_error": bool(d.get("is_error", True)) or code != 0,
                    "terminal_reason": d.get("terminal_reason"),
                    "permission_denials": len(d.get("permission_denials") or []),
                    "files_changed": stat, "answer_words": len(answer.split()),
                }

                if cfg["kind"] in ("code", "fix"):
                    try:
                        r = sh(["swift", "build"], cwd=wt, check=False, timeout=900)
                        own_ok, log = r.returncode == 0, r.stdout
                        if own_ok:
                            r = sh(["swift", "test"], cwd=wt, check=False, timeout=900)
                            own_ok, log = r.returncode == 0, log + r.stdout
                    except subprocess.TimeoutExpired:
                        own_ok, log = False, "timeout after 900 s"
                    Path(f"{stem}.own-tests.log").write_text(log)
                    acc = run_acceptance(wt, cfg["acceptance"])
                    Path(f"{stem}.acceptance.log").write_text(acc.pop("log"))
                    rec.update(own_tests_pass=own_ok, acc_status=acc["status"],
                               acc_passed=acc["passed"], acc_total=acc["total"],
                               acc_score=acc["passed"] / acc["total"] if acc["total"] else None)
                else:
                    rec.update(read_only_respected=(stat == ""),
                               rubric=rubric_score(answer, cfg["rubric"]) if "rubric" in cfg else None)
                rec["wall_s"] = int(time.time() - t0)
                write_json_line(LOG, rec)

                c = rec["cost_usd"]
                line = f"    ${c:.4f}" if c is not None else "    cost n/a"
                line += f" · turns {rec['turns']} · out {rec['output_tokens']}"
                if "acc_status" in rec:
                    line += f" · own tests {'pass' if rec['own_tests_pass'] else 'FAIL'}"
                    line += f" · acceptance {rec['acc_passed']}/{rec['acc_total']} ({rec['acc_status']})"
                else:
                    line += f" · answer {rec['answer_words']} words"
                print(line)

                if cfg["kind"] in ("code", "fix") and not stat:
                    print(f"\n✗ {task} ({arm}) changed no files. Last message:\n{answer[:800]}\n"
                          "Stopping so a setup problem does not burn the whole run.")
                    sys.exit(1)

    print()
    subprocess.run([sys.executable, str(Path(__file__).with_name("summarize.py"))])


if __name__ == "__main__":
    main()
