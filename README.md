# claude-md-playground

Does a `CLAUDE.md` change what Claude Code costs to build an app?

This repo builds the same iOS app (a TMDB movie browser, SwiftUI + MVVM) with Claude Code,
with **identical prompts**, once without a `CLAUDE.md` and once with the rules of the
[caveman](https://github.com/JuliusBrussee/caveman) skill (v4.0.1), and compares cost,
tokens and quality.

## Result

**Whether caveman saves money depends on where you start. Quality was the same everywhere.**

| Configuration | vs | Cost per session (95% CI) |
|---|---|---:|
| caveman rules as `CLAUDE.md` | Sonnet | +3.8% [−1.0, +8.9] |
| full caveman tool, Sonnet kept | Sonnet | +8.0% [+2.9, +13.2] |
| full caveman tool with Auto | Sonnet | +203% [+145, +275] |
| full caveman tool, Opus xhigh kept | Opus xhigh | −13.4% [−27.9, +4.0] |
| full caveman tool with Auto | Opus xhigh | **−48.6% [−56.4, −39.5]** |

On Sonnet, caveman never saved: in a coding session most output is code, most cost is re-reading
context, and Auto moved tasks up to Opus. Against Opus at xhigh effort, caveman's own baseline,
caveman with Auto halved the cost, close to the 54% it reports, mostly by lowering Opus's effort.
Its compression found nothing to compress in this project.
Full write-up: **[results/REPORT.md](results/REPORT.md)**.

## Where the code is

`main` holds the starting skeleton, the benchmark tooling and the results. The app itself was
written by Claude Code on two branches, one commit per step (`01-models` … `08-app-shell`):

| Branch | CLAUDE.md | |
|---|---|---|
| [`baseline`](../../tree/baseline) | none | [commits](../../commits/baseline) |
| [`caveman`](../../tree/caveman) | [caveman rules](bench/arms/caveman/CLAUDE.md) | [commits](../../commits/caveman) |

Everything else is the same in both: starting code, prompts, model (Sonnet), tool permissions.
Each step is a fresh headless Claude Code session.

## Experiments

| | 1: chained | 2: rules as CLAUDE.md | 3: full tool on Sonnet | 4: full tool on Opus xhigh |
|---|---|---|---|---|
| Baseline | Sonnet | Sonnet | Sonnet | Opus 5.5, `--effort xhigh` |
| caveman arm | rules in `CLAUDE.md` | rules in `CLAUDE.md` | `caveman wrap claude`, with and without Auto | same, Opus xhigh kept, with and without Auto |
| Design | each branch builds on its own previous step | every task starts from the same reference commit in every arm | same as 2 | same as 2 |
| Tasks | 8 build steps | 8 build steps + 3 seeded bug fixes + 3 explain/review questions | same as 2 | same as 2 |
| Repetitions | 1 | 3 per task and arm | 3 (Auto: 1) | 1 |
| Quality check | the agent's own tests | 53 hidden acceptance tests | same as 2 | same as 2 |
| Cost difference | +2.7% (≈ −10 to +25) | +3.8% [−1.0, +8.9] | +8.0% [+2.9, +13.2]; Auto +203% | −13.4% [−27.9, +4.0]; Auto −48.6% |
| Results | [results/RESULTS.md](results/RESULTS.md) | [results/exp2/RESULTS.md](results/exp2/RESULTS.md) | [results/exp3/RESULTS.md](results/exp3/RESULTS.md) | [results/exp4/RESULTS.md](results/exp4/RESULTS.md) |

Experiment 1 is realistic but too noisy to conclude anything: after a few steps the two
branches work on different code. Experiment 2 removes that drift and repeats every task.
Experiment 3 replaces the CLAUDE.md with the real caveman install (proxy, compression, voice),
run per session with `caveman wrap`, plus an arm where caveman's Auto picks the model.
Experiment 4 repeats experiment 3 from caveman's own baseline, Opus at xhigh effort.

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
  exp3/                               experiment 3: runs the same tasks through `caveman wrap`
  exp4/                               experiment 4: the exp 3 harness with Opus xhigh arms
results/
  REPORT.md                           findings, method, limits
  run-1/  RESULTS.md                  experiment 1 data
  exp2/  exp3/  exp4/                 per session JSON, answer, patch, test logs
```

## Running it yourself (macOS)

Requirements: Xcode 16+, Claude Code (`claude`) logged in, `python3`.

```bash
./bench/setup.sh                     # creates branches baseline + caveman and their worktrees
./bench/run.sh                       # experiment 1: steps 01–08 on both branches

python3 bench/exp2/calibrate.py      # experiment 2: check the hidden tests (no Claude calls)
python3 bench/exp2/run.py            # 14 tasks × 2 arms × 3 trials, resumable

# experiment 3 needs the caveman CLI and its binaries (caveman setup --install), not wired globally
caveman disable claude
python3 bench/exp3/run.py --arms baseline,caveman --trials 3
python3 bench/exp3/run.py --arms caveman-auto --trials 1   # needs `caveman login`
python3 bench/exp4/run.py --trials 1                       # Opus xhigh, with and without caveman
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
