#!/usr/bin/env python3
"""Experiment 4: caveman against a high-end setup (Opus at xhigh effort), caveman's own baseline.

Same tasks, reference commits and hidden acceptance tests as experiments 2 and 3; no CLAUDE.md.

  opus-xhigh          claude --model opus --effort xhigh               caveman's benchmark baseline
  caveman-opus-xhigh  caveman wrap claude --model opus --effort xhigh  caveman's tool, model fixed
  caveman-auto        caveman wrap claude --model caveman-auto[1m]      caveman picks model and effort

Usage (repo root, macOS):
    python3 bench/exp4/run.py --smoke                     # 2 cheap tasks, all arms: setup check
    python3 bench/exp4/run.py --trials 1                  # 14 tasks x 3 arms x 1 trial
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "exp3"))
import run as harness  # noqa: E402  (experiment 3 harness)

harness.EXP = "exp4"
harness.OUT = harness.ROOT / "results" / "exp4"
harness.LOG = harness.OUT / "trials.jsonl"
harness.SUMMARY = HERE / "summarize.py"
harness.ARMS = {
    "opus-xhigh": {"wrap": None, "env": {}, "model": "opus", "flags": ["--effort", "xhigh"]},
    "caveman-opus-xhigh": {"wrap": [], "env": {"CAVEMAN_DEFAULT_MODE": "caveman"}, "model": "opus",
                           "flags": ["--effort", "xhigh"]},
    "caveman-auto": {"wrap": [], "env": {"CAVEMAN_DEFAULT_MODE": "caveman"}, "model": "caveman-auto[1m]"},
}

if __name__ == "__main__":
    if "--arms" not in sys.argv:
        sys.argv += ["--arms", ",".join(harness.ARMS)]
    harness.main()
