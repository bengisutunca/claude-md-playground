#!/usr/bin/env python3
"""Builds results/exp2/RESULTS.md from results/exp2/trials.jsonl.

Arms are compared on pairs: the same task and trial number in both arms. The effect is the
ratio caveman / baseline; we average log-ratios across pairs and report the geometric-mean
ratio as a percentage with a 95% confidence interval (t distribution).
"""
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import OUT, TASKS, read_json_lines

# Two-sided 95% t critical values by degrees of freedom.
T95 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262,
       10: 2.228, 11: 2.201, 12: 2.179, 13: 2.160, 14: 2.145, 15: 2.131, 16: 2.120, 17: 2.110,
       18: 2.101, 19: 2.093, 20: 2.086, 22: 2.074, 24: 2.064, 26: 2.056, 28: 2.048, 30: 2.042,
       40: 2.021, 60: 2.000, 120: 1.980}


def t95(df):
    if df <= 0:
        return float("nan")
    keys = sorted(T95)
    for k in keys:
        if df <= k:
            return T95[k]
    return 1.96


def ratio_ci(pairs):
    """pairs: [(baseline, caveman)] → (pct, lo, hi, n) from mean log-ratio."""
    logs = [math.log(c / b) for b, c in pairs if b and c and b > 0 and c > 0]
    n = len(logs)
    if n == 0:
        return None
    m = statistics.mean(logs)
    if n < 2:
        return (math.exp(m) - 1) * 100, None, None, n
    se = statistics.stdev(logs) / math.sqrt(n)
    h = t95(n - 1) * se
    return (math.exp(m) - 1) * 100, (math.exp(m - h) - 1) * 100, (math.exp(m + h) - 1) * 100, n


def fmt_ci(r):
    if not r:
        return "n/a"
    pct, lo, hi, n = r
    if lo is None:
        return f"{pct:+.1f}% (n={n})"
    return f"{pct:+.1f}% [{lo:+.1f}, {hi:+.1f}] (n={n})"


def mean(xs):
    xs = [x for x in xs if x is not None]
    return statistics.mean(xs) if xs else None


def f(v, spec):
    return "–" if v is None else spec.format(v)


def main():
    rows = read_json_lines(OUT / "trials.jsonl")
    if not rows:
        print("No experiment 2 results yet.")
        return
    idx = {(r["task"], r["arm"], r["trial"]): r for r in rows}
    tasks = [t for t in TASKS if any(r["task"] == t for r in rows)]

    def pairs(task_filter, key):
        out = []
        for (t, arm, k), b in idx.items():
            if arm != "baseline" or not task_filter(t):
                continue
            c = idx.get((t, "caveman", k))
            if c and b.get(key) is not None and c.get(key) is not None:
                out.append((b[key], c[key]))
        return out

    models = sorted({r["model"] for r in rows})
    trials = max(r["trial"] for r in rows)
    L = ["# Experiment 2: checkpoint mode, baseline vs caveman CLAUDE.md", "",
         f"Model: {', '.join(models)} · up to {trials} trials per task and arm · {len(rows)} sessions. "
         "Every trial starts from the same reference commit in both arms. "
         "Δ = caveman vs baseline, geometric mean over paired trials, with 95% confidence interval. "
         "A CI that includes 0 means no detectable difference.", ""]

    groups = [("All tasks", lambda t: True),
              ("Code (01–08)", lambda t: TASKS[t]["kind"] == "code"),
              ("Bug fix (d1–d3)", lambda t: TASKS[t]["kind"] == "fix"),
              ("Explain / review (x1–x3)", lambda t: TASKS[t]["kind"] == "explain")]
    L += ["## Effect of caveman", "",
          "| Group | Cost Δ | Output tokens Δ | Turns Δ |", "|---|---|---|---|"]
    for name, flt in groups:
        if not any(flt(t) for t in tasks):
            continue
        L.append(f"| {name} | {fmt_ci(ratio_ci(pairs(flt, 'cost_usd')))} | "
                 f"{fmt_ci(ratio_ci(pairs(flt, 'output_tokens')))} | {fmt_ci(ratio_ci(pairs(flt, 'turns')))} |")
    L.append("")

    # Quality
    L += ["## Quality", "",
          "| Group | baseline acceptance | caveman acceptance | baseline own tests pass | caveman own tests pass |",
          "|---|---:|---:|---:|---:|"]
    for name, flt in groups[1:3]:
        sel = {a: [r for r in rows if r["arm"] == a and flt(r["task"]) and "acc_score" in r] for a in ("baseline", "caveman")}
        if not sel["baseline"] and not sel["caveman"]:
            continue
        acc = {a: mean([r["acc_score"] for r in sel[a]]) for a in sel}
        own = {a: mean([1.0 if r["own_tests_pass"] else 0.0 for r in sel[a]]) for a in sel}
        L.append(f"| {name} | {f(acc['baseline'] and acc['baseline'] * 100, '{:.1f}%')} | "
                 f"{f(acc['caveman'] and acc['caveman'] * 100, '{:.1f}%')} | "
                 f"{f(own['baseline'] and own['baseline'] * 100, '{:.0f}%')} | "
                 f"{f(own['caveman'] and own['caveman'] * 100, '{:.0f}%')} |")
    L += ["", "Acceptance = share of hidden acceptance tests passed (the agent never sees them).", ""]

    # Per task
    L += ["## Per task (mean over trials)", "",
          "| Task | n | baseline $ | caveman $ | Δ $ | baseline out tok | caveman out tok | "
          "baseline turns | caveman turns | quality b / c |",
          "|---|---:|---:|---:|---|---:|---:|---:|---:|---|"]
    for t in tasks:
        b = [r for r in rows if r["task"] == t and r["arm"] == "baseline"]
        c = [r for r in rows if r["task"] == t and r["arm"] == "caveman"]
        kind = TASKS[t]["kind"]
        if kind == "explain":
            if "rubric" in TASKS[t]:
                q = (f"rubric {f(mean([r['rubric'] for r in b]), '{:.0%}')} / "
                     f"{f(mean([r['rubric'] for r in c]), '{:.0%}')}")
            else:
                q = f"{f(mean([r['answer_words'] for r in b]), '{:.0f}')} / {f(mean([r['answer_words'] for r in c]), '{:.0f}')} words"
        else:
            q = (f"{f(mean([r['acc_score'] for r in b]), '{:.0%}')} / "
                 f"{f(mean([r['acc_score'] for r in c]), '{:.0%}')}")
        L.append(
            f"| {t} | {min(len(b), len(c))} | {f(mean([r['cost_usd'] for r in b]), '{:.3f}')} | "
            f"{f(mean([r['cost_usd'] for r in c]), '{:.3f}')} | {fmt_ci(ratio_ci(pairs(lambda x: x == t, 'cost_usd')))} | "
            f"{f(mean([r['output_tokens'] for r in b]), '{:,.0f}')} | {f(mean([r['output_tokens'] for r in c]), '{:,.0f}')} | "
            f"{f(mean([r['turns'] for r in b]), '{:.1f}')} | {f(mean([r['turns'] for r in c]), '{:.1f}')} | {q} |")
    L.append("")

    totals = defaultdict(float)
    for r in rows:
        totals[r["arm"]] += r.get("cost_usd") or 0
    L += [f"Total spent: baseline ${totals['baseline']:.2f} · caveman ${totals['caveman']:.2f} "
          "(Claude Code `total_cost_usd`; an API-price estimate on a subscription).", ""]

    problems = [r for r in rows if r.get("is_error") or r.get("read_only_respected") is False
                or r.get("acc_status") in ("compile_error", "timeout")]
    if problems:
        L += ["## Sessions to look at", ""]
        for r in problems:
            why = []
            if r.get("is_error"):
                why.append(f"error ({r.get('terminal_reason')})")
            if r.get("read_only_respected") is False:
                why.append("edited files in a read-only task")
            if r.get("acc_status") in ("compile_error", "timeout"):
                why.append(f"acceptance {r['acc_status']}")
            L.append(f"- {r['task']} · {r['arm']} · trial {r['trial']}: {', '.join(why)}")
        L.append("")

    text = "\n".join(L)
    (OUT / "RESULTS.md").write_text(text + "\n")
    print(text)
    print(f"\nWritten to {OUT / 'RESULTS.md'}")


if __name__ == "__main__":
    main()
