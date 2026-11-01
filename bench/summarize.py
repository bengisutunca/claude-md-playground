#!/usr/bin/env python3
"""Builds results/RESULTS.md from every results/run-*/steps.jsonl.

Per run: a step-by-step table for each arm. Across runs: mean totals per arm and the
caveman-vs-baseline difference. Usage: python3 bench/summarize.py
"""
import json
import statistics
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESULTS = ROOT / "results"
ARMS = ["baseline", "caveman"]
METRICS = [  # key, label, format
    ("cost_usd", "Cost ($)", "{:.4f}"),
    ("turns", "Turns", "{:.0f}"),
    ("output_tokens", "Output tok", "{:,.0f}"),
    ("input_tokens", "Input tok", "{:,.0f}"),
    ("cache_write_tokens", "Cache write tok", "{:,.0f}"),
    ("cache_read_tokens", "Cache read tok", "{:,.0f}"),
    ("duration_ms", "Time (s)", None),
]


def load():
    rows = []
    for f in sorted(RESULTS.glob("run-*/steps.jsonl")):
        rows += [json.loads(l) for l in f.read_text().splitlines() if l.strip()]
    return rows


def num(v):
    return v if isinstance(v, (int, float)) else 0


def fmt(key, v):
    if key == "duration_ms":
        return f"{num(v) / 1000:.0f}"
    spec = next(f for k, _, f in METRICS if k == key)
    return spec.format(num(v))


def pct(a, b):
    return "n/a" if not a else f"{(b - a) / a * 100:+.1f}%"


def main():
    rows = load()
    if not rows:
        print("No results yet. Run ./bench/run.sh first.")
        return
    by_run = defaultdict(lambda: defaultdict(list))
    for r in rows:
        by_run[r["run"]][r["arm"]].append(r)

    out = ["# Benchmark results: baseline vs caveman CLAUDE.md", ""]
    models = sorted({r["model"] for r in rows})
    out += [f"Model: {', '.join(models)} · runs: {len(by_run)} · "
            "cost = Claude Code `total_cost_usd` (API-price estimate on a subscription).", ""]

    # ---- totals per run ----
    totals = defaultdict(lambda: defaultdict(list))  # arm -> metric -> [per-run total]
    for run in sorted(by_run):
        for arm in ARMS:
            steps = by_run[run].get(arm, [])
            for k, _, _ in METRICS:
                totals[arm][k].append(sum(num(s.get(k)) for s in steps))
            totals[arm]["tests_pass"].append(sum(bool(s.get("tests_pass")) for s in steps))
            totals[arm]["steps"].append(len(steps))

    out += ["## Summary (mean of run totals)", "",
            "| Metric | baseline | caveman | Δ caveman vs baseline |", "|---|---:|---:|---:|"]
    for k, label, _ in METRICS:
        a = statistics.mean(totals["baseline"][k]) if totals["baseline"][k] else 0
        b = statistics.mean(totals["caveman"][k]) if totals["caveman"][k] else 0
        out.append(f"| {label} | {fmt(k, a)} | {fmt(k, b)} | {pct(a, b)} |")
    for arm_label, key in [("Steps with passing tests", "tests_pass")]:
        a = totals["baseline"][key]; b = totals["caveman"][key]
        sa = totals["baseline"]["steps"]; sb = totals["caveman"]["steps"]
        out.append(f"| {arm_label} | {sum(a)}/{sum(sa)} | {sum(b)}/{sum(sb)} | |")
    if len(by_run) > 1:
        out += ["", "Cost per run (total $): "
                + " · ".join(f"{arm}: " + ", ".join(f"{c:.3f}" for c in totals[arm]["cost_usd"]) for arm in ARMS)]
    out.append("")

    # ---- per step, per run ----
    for run in sorted(by_run):
        out += [f"## Run {run}: step by step", "",
                "| Step | baseline $ | caveman $ | Δ $ | baseline out tok | caveman out tok | "
                "baseline turns | caveman turns | tests (b / c) |",
                "|---|---:|---:|---:|---:|---:|---:|---:|---|"]
        steps = sorted({r["step"] for r in rows if r["run"] == run})
        idx = {(r["arm"], r["step"]): r for r in by_run[run]["baseline"] + by_run[run]["caveman"]}
        for st in steps:
            b = idx.get(("baseline", st), {}); c = idx.get(("caveman", st), {})
            t = lambda r: "–" if not r else ("✅" if r.get("tests_pass") else "❌")
            out.append(
                f"| {st} | {fmt('cost_usd', b.get('cost_usd'))} | {fmt('cost_usd', c.get('cost_usd'))} | "
                f"{pct(num(b.get('cost_usd')), num(c.get('cost_usd')))} | "
                f"{fmt('output_tokens', b.get('output_tokens'))} | {fmt('output_tokens', c.get('output_tokens'))} | "
                f"{fmt('turns', b.get('turns'))} | {fmt('turns', c.get('turns'))} | {t(b)} / {t(c)} |")
        out.append("")

    errors = [r for r in rows if r.get("is_error")]
    if errors:
        out += ["## Sessions that ended with an error", ""]
        out += [f"- run {r['run']} · {r['arm']} · {r['step']} · {r.get('subtype')}" for r in errors]
        out.append("")

    text = "\n".join(out)
    (RESULTS / "RESULTS.md").write_text(text + "\n")
    print(text)
    print(f"\nWritten to {RESULTS / 'RESULTS.md'}")


if __name__ == "__main__":
    main()
