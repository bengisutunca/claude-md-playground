# Experiment 2: checkpoint mode

Experiment 1 (`bench/run.sh`) builds the app step by step on two chained branches. It is
realistic but noisy: after a few steps the two arms work on different code, and one run gives
only 8 paired measurements. Its 95% confidence interval for the cost difference was roughly
−10% to +25%, so it could not tell whether caveman helps.

Experiment 2 changes three things:

| | Experiment 1 | Experiment 2 |
|---|---|---|
| Starting point of a step | the arm's own previous step | the same reference commit in both arms (`ref/NN`) |
| Repetitions | 1 per step | 3 trials per task and arm (`--trials`) |
| Quality check | the agent's own tests | hidden acceptance tests the agent never sees |
| Tasks | 8 build steps | 8 build steps + 3 seeded bugs + 3 explain/review questions |

The reference commits are the passing step commits of the `baseline` branch from experiment 1:
`ref/00` is the skeleton, `ref/NN` is baseline after step NN. Step NN always starts from
`ref/NN-1`. Bug and explain tasks start from `ref/08`, the finished app.

## Tasks

- **01–08 (code):** the experiment 1 prompts plus a *Required API* section, so the hidden
  acceptance tests can call the code. Same text in both arms.
- **d1–d3 (fix):** a bug is injected into `ref/08` before the session (pagination never
  loads, runtime shows "2h 4m", favorites vanish after relaunch). The prompt is a user bug report.
- **x1–x3 (explain):** read-only questions (explain pagination, review search, plan a genre
  filter). This is where caveman's rules act most, since the output is prose, not code.

## Files

```
tasks/                 prompts (01–08, d1–d3, x1–x3)
acceptance/            AcceptanceNN.swift, hidden tests copied in after each session
common.py              task list, reference tags, worktrees, test runner
calibrate.py           checks the acceptance tests on the reference commits (no Claude calls)
run.py                 runs the trials, resumable
summarize.py           writes results/exp2/RESULTS.md with confidence intervals
```

## Running it

```bash
python3 bench/exp2/calibrate.py           # 1. acceptance tests must pass on ref commits, bugs must fail
python3 bench/exp2/run.py --trials 1      # 2. one quick pass over all 14 tasks (~28 sessions)
python3 bench/exp2/run.py                 # 3. the full 3 trials (skips what is already done)
```

Per-trial output lands in `results/exp2/raw/<task>/<arm>-t<k>.*`: the Claude JSON, the final
answer (`.answer.md`), the code change (`.patch`), and the test logs.

## Reading the results

The effect is reported as caveman vs baseline over paired trials (same task, same trial
number), as a geometric-mean percentage with a 95% confidence interval. An interval that
contains 0 means the experiment found no difference at that precision.
