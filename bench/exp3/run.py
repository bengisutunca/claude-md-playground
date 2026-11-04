#!/usr/bin/env python3
"""Experiment 3: the full caveman tool (proxy, compression, voice, and optionally Auto).

Same tasks, reference commits and hidden acceptance tests as experiment 2. The arms differ
only in how Claude Code is launched:

  baseline      claude ...                       plain Claude Code, no caveman at all
  caveman       caveman wrap claude ...          all local modules on, CAVEMAN_DEFAULT_MODE=caveman
  caveman-auto  as caveman, with --model caveman-auto[1m] (caveman picks model and effort)

No CLAUDE.md is added in any arm. Every session gets a --workflow label so caveman's own
records can be matched to it.

Usage (repo root, macOS):
    python3 bench/exp3/run.py --smoke                   # 2 cheap tasks × baseline, caveman: setup check
    python3 bench/exp3/run.py --smoke --arms caveman-auto
    python3 bench/exp3/run.py                           # baseline + caveman, 14 tasks × 3 trials
    python3 bench/exp3/run.py --arms baseline,caveman,caveman-auto
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "exp2"))
from common import (PERM_FLAGS, ROOT, TASK_DIR, TASKS, ensure_refs, ensure_worktree, git, prepare,  # noqa: E402
                    read_json_lines, run_acceptance, sh, write_json_line)

OUT = ROOT / "results" / "exp3"
LOG = OUT / "trials.jsonl"
USER_SETTINGS = Path.home() / ".claude" / "settings.json"

ARMS = {
    "baseline":     {"wrap": None, "env": {}, "model": None},
    "caveman":      {"wrap": [], "env": {"CAVEMAN_DEFAULT_MODE": "caveman"}, "model": None},
    "caveman-auto": {"wrap": [], "env": {"CAVEMAN_DEFAULT_MODE": "caveman"}, "model": "caveman-auto[1m]"},
}
SMOKE_TASKS = ["d2-runtime-bug", "x1-explain-pagination"]


def settings_fingerprint():
    """Lines of ~/.claude/settings.json that would route or hook Claude Code through caveman."""
    if not USER_SETTINGS.exists():
        return ""
    # The caveman-blocks hook (Python script reuse) is ignored: user settings are not loaded in
    # any arm (--setting-sources project,local), and Blocks does not apply to a Swift project.
    return "\n".join(l for l in USER_SETTINGS.read_text().splitlines()
                     if ("caveman" in l.lower() and "caveman-blocks" not in l) or "ANTHROPIC_BASE_URL" in l)


def caveman_snapshot():
    """Per-model totals from caveman's local records (requests through its proxy)."""
    r = sh(["caveman", "stats", "--json", "--days", "2"], check=False)
    try:
        groups = json.loads(r.stdout).get("groups") or []
    except Exception:
        return None
    snap = {}
    for g in groups:
        m = g.get("model") or "?"
        cur = snap.setdefault(m, {"requests": 0, "input": 0, "output": 0, "cache_read": 0, "cache_write": 0, "usd": 0.0})
        cur["requests"] += g.get("requests") or 0
        cur["input"] += g.get("input_tokens") or 0
        cur["output"] += g.get("output_tokens") or 0
        cur["cache_read"] += g.get("cache_read_tokens") or 0
        cur["cache_write"] += g.get("cache_write_tokens") or 0
        cur["usd"] += g.get("api_equivalent_spend_usd") or g.get("api_spend_usd") or 0.0
    return snap


def snapshot_diff(before, after):
    if before is None or after is None:
        return None
    out = {}
    for m, a in after.items():
        b = before.get(m, {})
        d = {k: a[k] - b.get(k, 0) for k in a}
        if d["requests"]:
            d["usd"] = round(d["usd"], 6)
            out[m] = d
    return out


def preflight():
    for b in ["claude", "swift", "git", "caveman"]:
        if not shutil.which(b):
            sys.exit(f"✗ '{b}' not found in PATH")
    if os.environ.get("ANTHROPIC_BASE_URL"):
        sys.exit("✗ ANTHROPIC_BASE_URL is set in this shell; unset it so only caveman wrap routes traffic.")
    if settings_fingerprint():
        sys.exit("✗ ~/.claude/settings.json routes Claude Code through caveman for every session.\n"
                 "  Run `caveman disable claude` first, so only the wrapped arms use caveman.")
    help_text = sh(["claude", "--help"], check=False).stdout
    extra = []
    if "--setting-sources" in help_text:
        extra += ["--setting-sources", "project,local"]
    if "--strict-mcp-config" in help_text:
        extra += ["--strict-mcp-config"]
    return extra


def run_session(arm, wt, prompt, model, max_turns, extra, workflow, raw, stderr_path):
    cfg = ARMS[arm]
    env = {**os.environ, "DO_NOT_TRACK": "1", **cfg["env"]}
    launcher = ["claude"] if cfg["wrap"] is None else ["caveman", "wrap", *cfg["wrap"], "--workflow", workflow, "claude"]
    cmd = [*launcher, "-p", prompt, "--model", cfg["model"] or model, "--output-format", "json",
           "--max-turns", str(max_turns), *extra, *PERM_FLAGS]
    attempt, waited = 0, 0
    while attempt < 3:
        with open(raw, "w") as out, open(stderr_path, "w") as err:
            r = subprocess.run(cmd, cwd=wt, stdout=out, stderr=err, text=True, env=env)
        try:
            d = json.loads(Path(raw).read_text())
        except Exception:
            d = {}
        if d and d.get("terminal_reason") != "api_error" and not d.get("api_error_status"):
            return d, r.returncode
        msg = (d.get("result") or "").lower()
        if "limit" in msg and ("hit your" in msg or "resets" in msg) and waited < 8 * 3600:
            # Subscription usage limit: wait for the reset instead of burning retries.
            print(f"    ⏸ usage limit reached ({d.get('result')}). Waiting 10 min, then retrying.", flush=True)
            git("reset", "-q", "--hard", cwd=wt)
            git("clean", "-fdq", cwd=wt)
            time.sleep(600)
            waited += 600
            continue
        attempt += 1
        print(f"    ⚠ no usable result (attempt {attempt}), retrying in 30 s · see {stderr_path}", flush=True)
        shutil.copy(raw, f"{raw}.attempt{attempt}")
        git("reset", "-q", "--hard", cwd=wt)
        git("clean", "-fdq", cwd=wt)
        time.sleep(30)
    return d, r.returncode


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--trials", type=int, default=3)
    ap.add_argument("--arms", default="baseline,caveman")
    ap.add_argument("--only", default="")
    ap.add_argument("--smoke", action="store_true")
    ap.add_argument("--model", default=os.environ.get("MODEL", "sonnet"))
    ap.add_argument("--max-turns", type=int, default=80)
    args = ap.parse_args()

    arms = [a.strip() for a in args.arms.split(",") if a.strip()]
    for a in arms:
        if a not in ARMS:
            sys.exit(f"✗ unknown arm {a}; choose from {', '.join(ARMS)}")
    extra = preflight()
    ensure_refs()
    wts = {a: ensure_worktree(f"exp3-{a}") for a in arms}

    # Warm-up: the first session after a pause writes the shared prompt prefix to the provider
    # cache (~30k tokens) and later sessions read it cheaply. One unrecorded session per arm
    # makes every measured session start from the same warm cache.
    for a in arms:
        print(f"• warm-up · {a}")
        prepare(wts[a], "ref/08")
        warm = OUT / "warmup"
        warm.mkdir(parents=True, exist_ok=True)
        run_session(a, wts[a], "Reply with the single word OK. Do not use any tools.", args.model, 2,
                    extra, f"exp3-warmup-{a}", warm / f"{a}.json", warm / f"{a}.stderr")

    if args.smoke:
        tasks, trials, log = SMOKE_TASKS, 1, OUT / "smoke.jsonl"
    else:
        only = [p.strip() for p in args.only.split(",") if p.strip()]
        tasks = [t for t in TASKS if not only or any(t.startswith(p) for p in only)]
        trials, log = args.trials, LOG
    done = {(r["task"], r["arm"], r["trial"]) for r in read_json_lines(log)}
    todo = sum(1 for t in tasks for a in arms for k in range(1, trials + 1) if (t, a, k) not in done)
    print(f"Experiment 3{' (smoke)' if args.smoke else ''} · arms {', '.join(arms)} · "
          f"{len(tasks)} tasks × {trials} trials · {todo} sessions to run")

    for trial in range(1, trials + 1):
        for i, task in enumerate(tasks):
            cfg = TASKS[task]
            order = arms[(i + trial) % len(arms):] + arms[:(i + trial) % len(arms)]  # rotate run order
            prompt = (TASK_DIR / f"{task}.md").read_text()
            for arm in order:
                if (task, arm, trial) in done:
                    continue
                wt = wts[arm]
                base = OUT / ("smoke" if args.smoke else "raw") / task
                base.mkdir(parents=True, exist_ok=True)
                stem = base / f"{arm}-t{trial}"
                workflow = f"exp3-{'smoke-' if args.smoke else ''}{task}-{arm}-t{trial}"
                print(f"▶ trial {trial} · {task} · {arm}")
                prepare(wt, cfg["start"], bug=cfg.get("bug"))  # no CLAUDE.md in any arm

                t0 = time.time()
                before = caveman_snapshot() if ARMS[arm]["wrap"] is not None else None
                d, code = run_session(arm, wt, prompt, args.model, args.max_turns, extra, workflow,
                                      f"{stem}.json", f"{stem}.stderr")
                if not d or d.get("terminal_reason") == "api_error":
                    sys.exit(f"✗ {task} ({arm}) failed 3 times with no usable result; nothing recorded. "
                             f"See {stem}.stderr, then re-run the same command to resume.")
                answer = d.get("result", "") or ""
                Path(f"{stem}.answer.md").write_text(answer)
                git("add", "-A", cwd=wt)
                Path(f"{stem}.patch").write_text(git("diff", "--cached", "--binary", "HEAD", cwd=wt).stdout)
                stat = git("diff", "--cached", "--shortstat", "HEAD", cwd=wt).stdout.strip()

                by_model = snapshot_diff(before, caveman_snapshot()) if before is not None else None
                u = d.get("usage") or {}
                rec = {
                    "task": task, "kind": cfg["kind"], "arm": arm, "trial": trial, "workflow": workflow,
                    "model": ARMS[arm]["model"] or args.model,
                    "models_used": sorted((d.get("modelUsage") or {}).keys()),
                    "cost_by_model": {m: v.get("costUSD") for m, v in (d.get("modelUsage") or {}).items()},
                    "cost_usd": d.get("total_cost_usd"), "turns": d.get("num_turns"),
                    # caveman's own per-model record of this session; the source of truth for Auto,
                    # whose model id Claude Code cannot price (costBasis "unknown").
                    "caveman_by_model": by_model,
                    "caveman_usd": round(sum(v["usd"] for v in by_model.values()), 6) if by_model else None,
                    "duration_ms": d.get("duration_ms"),
                    "input_tokens": u.get("input_tokens"),
                    "cache_write_tokens": u.get("cache_creation_input_tokens"),
                    "cache_read_tokens": u.get("cache_read_input_tokens"),
                    "output_tokens": u.get("output_tokens"),
                    "is_error": bool(d.get("is_error", True)) or code != 0,
                    "terminal_reason": d.get("terminal_reason"),
                    "permission_denials": len(d.get("permission_denials") or []),
                    "files_changed": stat, "answer_words": len(answer.split()),
                }
                if cfg["kind"] in ("code", "fix"):
                    try:
                        r = sh(["swift", "build"], cwd=wt, check=False, timeout=900)
                        own_ok, tlog = r.returncode == 0, r.stdout
                        if own_ok:
                            r = sh(["swift", "test"], cwd=wt, check=False, timeout=900)
                            own_ok, tlog = r.returncode == 0, tlog + r.stdout
                    except subprocess.TimeoutExpired:
                        own_ok, tlog = False, "timeout after 900 s"
                    Path(f"{stem}.own-tests.log").write_text(tlog)
                    acc = run_acceptance(wt, cfg["acceptance"])
                    Path(f"{stem}.acceptance.log").write_text(acc.pop("log"))
                    rec.update(own_tests_pass=own_ok, acc_status=acc["status"], acc_passed=acc["passed"],
                               acc_total=acc["total"], acc_score=acc["passed"] / acc["total"])
                else:
                    rec["read_only_respected"] = stat == ""
                    if "rubric" in cfg:
                        t = answer.lower()
                        rec["rubric"] = sum(any(w.lower() in t for w in g) for g in cfg["rubric"]) / len(cfg["rubric"])
                rec["wall_s"] = int(time.time() - t0)
                write_json_line(log, rec)

                c = rec["cost_usd"]
                line = f"    ${c:.4f}" if c is not None else "    cost n/a"
                routed = ",".join(f"{m.replace('claude-', '')}×{v['requests']}" for m, v in (by_model or {}).items())
                line += f" · turns {rec['turns']} · out {rec['output_tokens']} · models {routed or ','.join(rec['models_used']) or '?'}"
                if rec["caveman_usd"] is not None:
                    line += f" · caveman ${rec['caveman_usd']:.4f}"
                line += (f" · acceptance {rec['acc_passed']}/{rec['acc_total']}" if "acc_status" in rec
                         else f" · answer {rec['answer_words']} words")
                print(line)

                if settings_fingerprint():
                    sys.exit("✗ caveman wired itself into ~/.claude/settings.json during the run; "
                             "this would leak into the baseline. Run `caveman disable claude`, then re-run.")
                if cfg["kind"] in ("code", "fix") and not stat:
                    sys.exit(f"✗ {task} ({arm}) changed no files. Last message:\n{answer[:800]}")

    if args.smoke:
        report = OUT / "smoke-caveman-stats.json"
        r = sh(["caveman", "stats", "--json", "--days", "1"], check=False)
        report.write_text(r.stdout)
        print(f"\nSmoke run done. caveman stats saved to {report.relative_to(ROOT)}")
    else:
        subprocess.run([sys.executable, str(HERE / "summarize.py")])


if __name__ == "__main__":
    main()
