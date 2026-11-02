# claude-md-playground

Does a `CLAUDE.md` change what Claude Code costs to build an app?

This repo builds the same iOS app (a TMDB movie browser, SwiftUI + MVVM) with Claude Code,
with **identical prompts**, once without a `CLAUDE.md` and once with the rules of the
[caveman](https://github.com/JuliusBrussee/caveman) skill (v4.0.1), and compares cost,
tokens and quality.

## Result

**Caveman made Claude's messages shorter, but not the work cheaper.**

| Caveman vs no CLAUDE.md (84 sessions, 95% confidence interval) | |
|---|---|
| Length of Claude's messages | **−22%** [−26, −18] |
| Total cost | **+3.8%** [−1.0, +8.9] |
| Output tokens | −1.5% [−7.8, +5.2] |
| Hidden acceptance tests passed | 100% in both |

In a coding session most output is code, which caveman's rules leave alone, and most of the
cost is the agent reading files and context. The rules also add about 1.2k tokens to every
session. Full write-up: **[results/REPORT.md](results/REPORT.md)**.

## Where the code is

`main` holds the starting skeleton, the benchmark tooling and the results. The app itself was
written by Claude Code on two branches, one commit per step (`01-models` … `08-app-shell`):

| Branch | CLAUDE.md | |
|---|---|---|
| [`baseline`](../../tree/baseline) | none | [commits](../../commits/baseline) |
| [`caveman`](../../tree/caveman) | [caveman rules](bench/arms/caveman/CLAUDE.md) | [commits](../../commits/caveman) |

Everything else is the same in both: starting code, prompts, model (Sonnet), tool permissions.
Each step is a fresh headless Claude Code session.

## Two experiments

| | Experiment 1: chained | Experiment 2: checkpoint |
|---|---|---|
| Design | each branch builds the app step by step on top of its own previous step | every task starts from the same reference commit in both arms |
| Tasks | 8 build steps | 8 build steps + 3 seeded bug fixes + 3 explain/review questions |
| Repetitions | 1 | 3 per task and arm |
| Quality check | the agent's own tests | 53 hidden acceptance tests the agent never sees |
| Cost difference | +2.7% (interval about −10% to +25%) | +3.8% [−1.0, +8.9] |
| Results | [results/RESULTS.md](results/RESULTS.md) | [results/exp2/RESULTS.md](results/exp2/RESULTS.md) |

Experiment 1 is realistic but too noisy to conclude anything: after a few steps the two
branches work on different code. Experiment 2 removes that drift and repeats every task, so
its interval is narrow enough to rule out savings larger than about 1%.

## Layout

```
Package.swift                         iOS 17+ / macOS 14+, Swift Testing
Sources/TMDBApp/                      MVVM skeleton (Models, Networking, Services, ViewModels, Views)
Tests/TMDBAppTests/Fixtures/          TMDB-shaped JSON, so tests never touch the network
bench/
  arms/caveman/CLAUDE.md              the file under test
  tasks/                              experiment 1 prompts (01–08)
  setup.sh  run.sh  redo.sh  reset.sh  summarize.py
  exp2/                               experiment 2: tasks, hidden acceptance tests, run.py, calibrate.py
results/
  REPORT.md                           findings, method, limits
  run-1/  RESULTS.md                  experiment 1 data
  exp2/                               experiment 2 data: per session JSON, answer, patch, test logs
```

## Running it yourself (macOS)

Requirements: Xcode 16+, Claude Code (`claude`) logged in, `python3`.

```bash
./bench/setup.sh                     # creates branches baseline + caveman and their worktrees
./bench/run.sh                       # experiment 1: steps 01–08 on both branches

python3 bench/exp2/calibrate.py      # experiment 2: check the hidden tests (no Claude calls)
python3 bench/exp2/run.py            # 14 tasks × 2 arms × 3 trials, resumable
```

Before running, rename `~/.claude/CLAUDE.md` if you have one and disable any caveman install;
both would affect both arms. The scripts load only project settings and warn about both.
Model: `MODEL=opus ./bench/run.sh` or `python3 bench/exp2/run.py --model opus` (default `sonnet`).

Cost is Claude Code's `total_cost_usd`. On a Pro/Max subscription it is an API-price
estimate, not a bill.

## The app

The app reads the TMDB API key from `TMDB_API_KEY` (environment or Info.plist); no key is
committed. The benchmark needs no key. Fixture titles are real; the other values are
approximate and for tests only.
