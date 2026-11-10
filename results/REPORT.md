# Does caveman make Claude Code cheaper?

**Short answer: no, not for building an app on Sonnet.** We built the same Swift/SwiftUI MVVM app
with Claude Code (Sonnet) with and without [caveman](https://github.com/JuliusBrussee/caveman)
(v4.0.1), in three experiments and 198 sessions. Quality was the same everywhere (100% of the
hidden acceptance tests). Cost was not lower in any configuration:

| Configuration (vs plain Claude Code) | Cost per session | 95% CI |
|---|---:|---|
| caveman rules as `CLAUDE.md` (exp 2) | **+3.8%** | −1.0 to +8.9 |
| full caveman tool, Sonnet kept (exp 3) | **+8.0%** | +2.9 to +13.2 |
| full caveman tool with Auto model routing (exp 3) | **+203%** (about 3×) | +145 to +275 |

Caveman's own "54% cheaper" figure for Auto compares it with Opus at xhigh effort, not with Sonnet;
see [Experiment 3](#experiment-3-the-full-caveman-tool) for how the two results fit together.

## Setup

- **App:** TMDB movie browser, Swift Package, iOS 17+, MVVM, Swift Testing; tests use JSON fixtures, never the network.
- **Tasks (exp 2 and 3):** 8 build steps, 3 seeded bug fixes, 3 explain/review questions. Every task
  starts from the same reference commit in every arm; prompts are identical word for word.
- **Quality:** 53 hidden acceptance tests the agent never sees, copied in after each session.
- **Measurement:** headless `claude -p --output-format json`, one fresh session per task, Sonnet,
  same tool permissions, user-level settings and plugins excluded. Cost is Claude Code's
  `total_cost_usd` (API-price estimate); for Auto, caveman's own per-model records (see below).
- **Repetition:** 3 trials per task and arm (Auto: 1), results as paired geometric-mean
  differences with 95% confidence intervals.

| | Exp 1: chained | Exp 2: rules as CLAUDE.md | Exp 3: full tool |
|---|---|---|---|
| caveman arm | rules in `CLAUDE.md` | rules in `CLAUDE.md` | `caveman wrap claude`, all local modules on, `CAVEMAN_DEFAULT_MODE=caveman` |
| Design | each arm builds on its own previous step | fixed reference commits | fixed reference commits |
| Sessions | 16 | 84 | 98 (+ Auto arm) |
| Cost Δ | +2.7% (CI ≈ −10 to +25) | +3.8% [−1.0, +8.9] | +8.0% [+2.9, +13.2] |

## Experiment 2: the rules as CLAUDE.md

| Metric (caveman vs baseline) | All tasks |
|---|---|
| Cost | +3.8% [−1.0, +8.9] |
| Output tokens | −1.5% [−7.8, +5.2] |
| Final message words | **−22.1%** [−26.3, −17.6] |
| Cache write tokens | +8.9% [+4.3, +13.6] |

The rules work as advertised on prose: Claude's messages were 22% shorter with no quality loss.
But in a coding session most output is code, which the rules leave alone, and most cost is
input: files, tool results and the conversation re-read on every turn. The rules themselves add
about 1.2k tokens to every session (+9% cache writes), which outweighs the shorter messages.

## Experiment 3: the full caveman tool

**Without Auto (Sonnet kept), caveman cost 8% more** [+2.9, +13.2], 22% more on bug fixes.

- **Compression never triggered.** Caveman's proxy saw every request and saved 0 tokens
  ("nothing compressible in this session"). Its input compression targets long logs, large JSON
  and test output; this project's tool output is short Swift files and short test runs. On a
  Pro/Max login it also only compresses the live part of the context.
- **The extra cost is context the tool adds.** Cache reads rose 73% [+56, +91] per session: the
  wrapped sessions carry more tool definitions and instructions, read again on every turn.
  Cache reads are cheap, so this shows up as +8%, not +73%.
- **The voice was weaker than as a CLAUDE.md.** Message words fell only 4% [−8, 0] here, against
  22% in experiment 2.

**With Auto, caveman cost about 3× as much** (+203% [+145, +275], 14 tasks): Auto sent 13 of 14
tasks to **Opus 5.5** instead of Sonnet. Quality stayed at 100%, so the stronger model bought
nothing measurable on these tasks.

**Why this does not contradict caveman's "54% cheaper, same score".** Caveman's own Auto
benchmark ([docs/AUTO-BENCHMARK.md](https://github.com/JuliusBrussee/caveman/blob/v4.0.1/docs/AUTO-BENCHMARK.md),
v4.0.1) measures something else:

| | Caveman's benchmark | This experiment |
|---|---|---|
| Baseline | Opus 5.5 at **xhigh** effort on every request | Sonnet 5.5, default effort |
| What Auto chose | Opus medium 87%, Opus high 8%, Sonnet 5% of requests | Opus for 13 of 14 tasks |
| Tasks | 85 paired coding tasks (SWE-Interact, SWE-Together), 1 attempt each | 14 tasks of this app, 1 attempt each |
| Quality | 43.7% vs 44.3% resolved, gap −0.5 points [−6.8, +5.7] | 100% vs 100% hidden tests |
| Cost | **0.46×** baseline ($3.59 vs $7.83 per attempt) | **≈3×** baseline |
| Status | interim: 85 of 169 tasks done | complete |

Auto behaves the same way in both: it mostly picks Opus (at medium effort in caveman's runs; this
experiment did not record the effort). Against Opus at xhigh that is a step down, so it saves money;
against Sonnet it is a step up, so it costs more. The
benchmark says as much itself: *"Most of the saving comes from lower effort (Opus xhigh to Opus
medium or high), not from cheaper models. Against an agent already on Opus at medium effort,
expect much less. Not measured."* An agent already on Sonnet was not measured there either; this
experiment fills that gap. Auto's saving depends on where you start.

**Measuring Auto.** Claude Code cannot price the `caveman-auto[1m]` model id (`costBasis:
unknown`), and on the one task Auto sent to Sonnet it billed Opus rates ($0.22 instead of $0.11).
Auto's cost is therefore taken from caveman's own per-model records, diffed before and after each
session. On the caveman arm, where both sources exist, they agree exactly (0.0% difference over 42 sessions).

## What this means

1. **Talking less is not where coding cost is.** Output prose is a small share; reading context is
   the large one. Shortening messages cannot move the total much.
2. **Every line in CLAUDE.md, and every tool definition, is paid on every turn.** Instruction files
   and add-ons should earn their tokens.
3. **Model choice dominates.** The only large effect in 198 sessions came from switching models.
4. **Check what a saving is measured against.** Caveman's figures are real for its own baselines
   (a chat answer, Opus at xhigh, noisy log files); they did not carry over to this workload.

## Limits

- One model (Sonnet), one app, one language, a Pro/Max login. Chat-heavy work, API-key billing,
  or large noisy tool output (where caveman's compression applies) may give different results.
- The Auto arm has 1 trial per task, enough for a 3× effect, not for fine detail.
- The hidden tests hit a ceiling (100% everywhere): they show that no arm lost quality, but cannot rank the arms.
- `total_cost_usd` is an API-price estimate on a subscription, not an invoice.

## Data

| | Results | Raw data |
|---|---|---|
| Exp 1 | `results/RESULTS.md` | `results/run-1/`, branches `baseline` and `caveman` |
| Exp 2 | `results/exp2/RESULTS.md` | `results/exp2/trials.jsonl`, `results/exp2/raw/` |
| Exp 3 | `results/exp3/RESULTS.md` | `results/exp3/trials.jsonl`, `results/exp3/raw/` |

Each session's raw folder holds Claude Code's JSON, the final answer, the code change (`.patch`)
and the test logs.
