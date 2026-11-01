# claude-md-playground

Does a `CLAUDE.md` change what Claude Code costs to build an app?

This repo builds the same iOS app (a TMDB movie browser, SwiftUI + MVVM) twice, with
**identical prompts**, on two branches:

| Branch     | Difference                                                                                     |
|------------|------------------------------------------------------------------------------------------------|
| `baseline` | No `CLAUDE.md`                                                                                 |
| `caveman`  | `CLAUDE.md` = the rules of the [caveman](https://github.com/JuliusBrussee/caveman) skill (v4.0.1) |

Everything else is the same: the starting code, the eight task prompts, the model, the
permission settings in `.claude/settings.json`. Every step is a fresh headless Claude Code
session, and the harness records the cost and token usage Claude Code reports for it.

## Layout

```
Package.swift                     iOS 17+ / macOS 14+, Swift Testing
Sources/TMDBApp/
  Models/  Networking/  Services/  ViewModels/  Views/     MVVM layers (filled by the benchmark)
Tests/TMDBAppTests/
  Fixtures/*.json                 TMDB-shaped responses, so tests never touch the network
  FixtureLoader.swift  SmokeTests.swift
.claude/settings.json             same tool permissions for both arms (installed by setup.sh from bench/claude-settings.json)
bench/
  tasks/01-models.md … 08-app-shell.md   the prompts, given word for word to both arms
  arms/caveman/CLAUDE.md                 the file added on the caveman branch
  setup.sh   run.sh   summarize.py
results/                          per-run raw JSON, test logs, steps.jsonl, RESULTS.md
```

On the arm branches, `bench/` and `results/` are removed, so the agent under test only sees the app.

## Running it (macOS)

Requirements: Xcode 16+ (Swift 6 toolchain), Claude Code logged in, `python3`.

```bash
./bench/setup.sh          # commits main, creates branches baseline + caveman, worktrees in ../claude-md-playground-wt/
./bench/run.sh            # runs steps 01–08 on both arms, commits each step, writes results/run-1/
```

Options: `MODEL=opus ./bench/run.sh` (default `sonnet`), `RUN=2 ./bench/run.sh` to repeat on fresh
branches `baseline-r2` / `caveman-r2`, `ONLY=03` for a single step. An interrupted run resumes
where it stopped. `python3 bench/summarize.py` rebuilds `results/RESULTS.md` at any time.

Before running, make sure nothing outside the repo affects only one arm, or both:
- rename `~/.claude/CLAUDE.md` if you have one,
- disable any caveman install (CLI, plugin or global skill).
The script warns about both and loads only project settings (`--setting-sources project,local`).

## Reading the results

- **Cost** is Claude Code's `total_cost_usd`. On a Pro/Max subscription it is an API-price estimate, not a bill; token counts are the harder numbers.
- **Output tokens** are where caveman's rules act; input and cache tokens mostly come from code and tool output, which the rules do not shorten. The rules themselves add about 1.2k input tokens per request.
- **Tests** must pass in both arms for a cost difference to mean anything. A cheaper arm that breaks the build is not cheaper.
- One run is noisy. Repeat with `RUN=2`, `RUN=3` and compare the mean.

## The app

TMDB API key: the app reads `TMDB_API_KEY` from the environment or from the app's Info.plist.
It is never committed (`Secrets.xcconfig` and `.env` are git-ignored). The benchmark itself needs no key.

Fixture data is shaped like TMDB responses; titles are real, the other values are approximate and for tests only.
