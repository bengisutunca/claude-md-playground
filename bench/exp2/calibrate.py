#!/usr/bin/env python3
"""Checks the hidden acceptance tests before spending money on Claude sessions.

1. Each AcceptanceNN must compile and pass on ref/NN (baseline's own solution of step NN),
   and pass again on ref/08 for the files the bug tasks reuse.
2. Each seeded bug must apply cleanly on ref/08 and make its acceptance test fail.
No Claude calls; only `swift test`. Usage: python3 bench/exp2/calibrate.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import OUT, TASKS, ensure_refs, ensure_worktree, prepare, run_acceptance

def main():
    ensure_refs()
    wt = ensure_worktree("exp2-calibrate")
    checks = []  # (label, ref, bug, acceptance, expect)
    for task, cfg in TASKS.items():
        if cfg["kind"] == "code":
            n = task[:2]
            checks.append((f"{task} on ref/{n}", f"ref/{n}", None, cfg["acceptance"], "pass"))
    for name in sorted({c["acceptance"] for c in TASKS.values() if c["kind"] == "fix"}):
        checks.append((f"{name} on ref/08", "ref/08", None, name, "pass"))
    for task, cfg in TASKS.items():
        if cfg["kind"] == "fix":
            checks.append((f"{task} bug on ref/08", "ref/08", cfg["bug"], cfg["acceptance"], "fail"))

    lines, ok_all = [], True
    for label, ref, bug, acc, expect in checks:
        try:
            prepare(wt, ref, bug=bug)
            r = run_acceptance(wt, acc)
            got = r["status"]
            ok = (got == "pass") if expect == "pass" else (got == "fail" and r["passed"] < r["total"])
            detail = f"{r['passed']}/{r['total']} {got}"
            if not ok:
                tail = "\n".join(l for l in r["log"].splitlines()
                                 if "error:" in l or "✘" in l or "Expectation failed" in l)[:3000]
                detail += "\n" + tail
        except Exception as e:
            ok, detail = False, f"ERROR {e}"
        ok_all &= ok
        line = f"{'✅' if ok else '❌'} {label:<38} expect {expect:<4} → {detail}"
        print(line, flush=True)
        lines.append(line)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "calibration.txt").write_text("\n".join(lines) + "\n")
    print("\nAll checks passed." if ok_all else "\nSome checks failed: send results/exp2/calibration.txt.")
    sys.exit(0 if ok_all else 1)


if __name__ == "__main__":
    main()
