#!/usr/bin/env python3
"""Builds results/exp4/RESULTS.md with the experiment 3 summary code, for the experiment 4 arms."""
import sys
from pathlib import Path

import importlib.util

HERE = Path(__file__).resolve().parent
# Load experiment 3's summary under its own name: it imports experiment 2's module "summarize".
_spec = importlib.util.spec_from_file_location("exp3_summary", HERE.parent / "exp3" / "summarize.py")
s = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(s)

s.OUT = s.ROOT / "results" / "exp4"
s.TITLE = "# Experiment 4: caveman against Opus at xhigh effort"
s.ARM_ORDER = ("opus-xhigh", "caveman-opus-xhigh", "caveman-auto")
s.COMPARISONS = [("opus-xhigh", "caveman-opus-xhigh"), ("opus-xhigh", "caveman-auto"),
                 ("caveman-opus-xhigh", "caveman-auto")]
s.INTRO = ("Baseline is caveman's own benchmark baseline, Opus 5.5 at xhigh effort. Same tasks, reference "
           "commits and hidden tests as experiments 2 and 3; no CLAUDE.md in any arm.")

if __name__ == "__main__":
    s.main()
