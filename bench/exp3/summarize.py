#!/usr/bin/env python3
"""Builds results/exp3/RESULTS.md: each caveman arm vs baseline (and Auto vs caveman),
paired by task and trial, geometric-mean ratio with 95% confidence interval."""
import statistics
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "exp2"))
from common import ROOT, TASKS, read_json_lines  # noqa: E402
from summarize import fmt_ci, ratio_ci  # noqa: E402

OUT = ROOT / "results" / "exp3"
GROUPS = [("All tasks", lambda t: True),
          ("Code (01–08)", lambda t: TASKS[t]["kind"] == "code"),
          ("Bug fix (d1–d3)", lambda t: TASKS[t]["kind"] == "fix"),
          ("Explain / review (x1–x3)", lambda t: TASKS[t]["kind"] == "explain")]
METRICS = [("cost", "Cost"), ("output_tokens", "Output tokens"), ("turns", "Turns"),
           ("answer_words", "Message words")]


def mean(xs):
    xs = [x for x in xs if x is not None]
    return statistics.mean(xs) if xs else None


def main():
    rows = read_json_lines(OUT / "trials.jsonl")
    if not rows:
        print("No experiment 3 results yet.")
        return
    for r in rows:
        # Claude Code cannot price the caveman-auto model id; use caveman's per-model record there.
        r["cost"] = r.get("caveman_usd") if r["arm"] == "caveman-auto" and r.get("caveman_usd") else r.get("cost_usd")
    idx = {(r["task"], r["arm"], r["trial"]): r for r in rows}
    arms = [a for a in ("baseline", "caveman", "caveman-auto") if any(r["arm"] == a for r in rows)]

    def pairs(a, b, flt, key):
        out = []
        for (t, arm, k), ra in idx.items():
            if arm != a or not flt(t):
                continue
            rb = idx.get((t, b, k))
            if rb and ra.get(key) and rb.get(key):
                out.append((ra[key], rb[key]))
        return out

    comparisons = [(a, b) for a, b in [("baseline", "caveman"), ("baseline", "caveman-auto"), ("caveman", "caveman-auto")]
                   if a in arms and b in arms]
    L = ["# Experiment 3: the full caveman tool", "",
         f"Arms: {', '.join(arms)} · {len(rows)} sessions. Same tasks, reference commits and hidden tests as "
         "experiment 2; no CLAUDE.md in any arm. Δ = second arm vs first, geometric mean over paired "
         "trials, 95% confidence interval. An interval that includes 0 means no detectable difference.", ""]
    for a, b in comparisons:
        L += [f"## {b} vs {a}", "", "| Group | " + " | ".join(m[1] + " Δ" for m in METRICS) + " |",
              "|---|" + "---|" * len(METRICS)]
        for name, flt in GROUPS:
            if not any(flt(r["task"]) for r in rows):
                continue
            L.append(f"| {name} | " + " | ".join(fmt_ci(ratio_ci(pairs(a, b, flt, k))) for k, _ in METRICS) + " |")
        L.append("")

    L += ["## Quality and models", "", "| Arm | sessions | acceptance (code + fix) | own tests pass | spend by model | $ per session |",
          "|---|---:|---:|---:|---|---:|"]
    for a in arms:
        rs = [r for r in rows if r["arm"] == a]
        acc = mean([r.get("acc_score") for r in rs if "acc_score" in r])
        own = mean([1.0 if r.get("own_tests_pass") else 0.0 for r in rs if "own_tests_pass" in r])
        models = {}
        for r in rs:
            src = ({m: v["usd"] for m, v in r["caveman_by_model"].items()} if r.get("caveman_by_model")
                   else r.get("cost_by_model") or {})
            for m, c in src.items():
                models[m] = models.get(m, 0) + (c or 0)
        mtxt = ", ".join(f"{m} ${c:.2f}" for m, c in sorted(models.items(), key=lambda x: -x[1]))
        L.append(f"| {a} | {len(rs)} | {acc * 100 if acc is not None else 0:.1f}% | {own * 100 if own is not None else 0:.0f}% | "
                 f"{mtxt} | {mean([r.get('cost') for r in rs]):.3f} |")
    check = [(r["cost_usd"], r["caveman_usd"]) for r in rows if r["arm"] == "caveman" and r.get("caveman_usd") and r.get("cost_usd")]
    L += ["", "Cost: Claude Code's `total_cost_usd` for baseline and caveman; caveman's own per-model record "
          "for caveman-auto, because Claude Code cannot price the `caveman-auto` model id. Both are API-price "
          "estimates on a subscription."]
    if check:
        L.append(f"Cross-check on the caveman arm, where both sources exist: caveman's record is "
                 f"{fmt_ci(ratio_ci(check))} vs Claude Code's.")
    L.append("")

    L += ["## Per task (mean over trials)", "",
          "| Task | " + " | ".join(f"{a} $" for a in arms) + " | " + " | ".join(f"{a} quality" for a in arms) + " |",
          "|---|" + "---:|" * (2 * len(arms))]
    for t in [t for t in TASKS if any(r["task"] == t for r in rows)]:
        costs, quals = [], []
        for a in arms:
            rs = [r for r in rows if r["task"] == t and r["arm"] == a]
            c = mean([r.get("cost") for r in rs])
            costs.append("–" if c is None else f"{c:.3f}")
            if TASKS[t]["kind"] == "explain":
                q = mean([r.get("rubric") for r in rs]) if "rubric" in TASKS[t] else None
                w = mean([r.get("answer_words") for r in rs])
                quals.append(f"rubric {q:.0%}" if q is not None else (f"{w:.0f} words" if w else "–"))
            else:
                q = mean([r.get("acc_score") for r in rs])
                quals.append("–" if q is None else f"{q:.0%}")
        L.append(f"| {t} | " + " | ".join(costs) + " | " + " | ".join(quals) + " |")
    L.append("")

    bad = [r for r in rows if r.get("is_error") or r.get("read_only_respected") is False
           or r.get("acc_status") in ("compile_error", "timeout")]
    if bad:
        L += ["## Sessions to look at", ""] + [
            f"- {r['task']} · {r['arm']} · trial {r['trial']}: error={r.get('is_error')} "
            f"acceptance={r.get('acc_status')} read_only={r.get('read_only_respected')}" for r in bad] + [""]

    text = "\n".join(L)
    (OUT / "RESULTS.md").write_text(text + "\n")
    print(text)
    print(f"\nWritten to {OUT / 'RESULTS.md'}")


if __name__ == "__main__":
    main()
