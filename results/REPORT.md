# Does caveman make Claude Code cheaper?

**Short answer: it depends on where you start.** We built the same Swift/SwiftUI MVVM app with
Claude Code, with and without [caveman](https://github.com/JuliusBrussee/caveman) (v4.0.1), in four
experiments and 240 sessions. Quality was the same everywhere (100% of the hidden acceptance tests).

| Configuration | vs | Cost per session | 95% CI |
|---|---|---:|---|
| caveman rules as `CLAUDE.md` (exp 2) | Sonnet | **+3.8%** | −1.0 to +8.9 |
| full caveman tool, Sonnet kept (exp 3) | Sonnet | **+8.0%** | +2.9 to +13.2 |
| full caveman tool with Auto (exp 3) | Sonnet | **+203%** (about 3×) | +145 to +275 |
| full caveman tool, Opus xhigh kept (exp 4) | Opus xhigh | **−13.4%** | −27.9 to +4.0 |
| full caveman tool with Auto (exp 4) | Opus xhigh | **−48.6%** (about half) | −56.4 to −39.5 |

For an agent on Sonnet, caveman did not save money in any configuration. For an agent on Opus at
xhigh effort, caveman's own baseline, caveman with Auto halved the cost at the same quality, close
to the 54% caveman reports. Almost all of that saving came from Auto lowering Opus's effort, not
from compression, which never triggered in this project.

## Setup

- **App:** TMDB movie browser, Swift Package, iOS 17+, MVVM, Swift Testing; tests use JSON fixtures, never the network.
- **Tasks (exp 2–4):** 8 build steps, 3 seeded bug fixes, 3 explain/review questions. Every task
  starts from the same reference commit in every arm; prompts are identical word for word.
- **Quality:** 53 hidden acceptance tests the agent never sees, copied in after each session.
- **Measurement:** headless `claude -p --output-format json`, one fresh session per task, Sonnet
  (exp 1–3) or Opus 5.5 (exp 4), same tool permissions, user-level settings and plugins excluded. Cost is Claude Code's
  `total_cost_usd` (API-price estimate); for Auto, caveman's own per-model records (see below).
- **Repetition:** 3 trials per task and arm (exp 3 Auto and exp 4: 1), results as paired geometric-mean
  differences with 95% confidence intervals.

| | Exp 1: chained | Exp 2: rules as CLAUDE.md | Exp 3: full tool on Sonnet | Exp 4: full tool on Opus xhigh |
|---|---|---|---|---|
| Baseline | Sonnet | Sonnet | Sonnet | Opus 5.5, `--effort xhigh` |
| caveman arm | rules in `CLAUDE.md` | rules in `CLAUDE.md` | `caveman wrap claude`, all local modules on; plus an Auto arm | same as exp 3, Opus xhigh kept; plus an Auto arm |
| Design | each arm builds on its own previous step | fixed reference commits | fixed reference commits | fixed reference commits |
| Sessions | 16 | 84 | 98 | 42 |
| Cost Δ | +2.7% (CI ≈ −10 to +25) | +3.8% [−1.0, +8.9] | +8.0% [+2.9, +13.2]; Auto +203% | −13.4% [−27.9, +4.0]; Auto −48.6% |

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
experiment fills that gap. Auto's saving depends on where you start; experiment 4 measures it
from caveman's own starting point.

**Measuring Auto.** Claude Code cannot price the `caveman-auto[1m]` model id (`costBasis:
unknown`), and on the one task Auto sent to Sonnet it billed Opus rates ($0.22 instead of $0.11).
Auto's cost is therefore taken from caveman's own per-model records, diffed before and after each
session. On the caveman arm, where both sources exist, they agree exactly (0.0% difference over 42 sessions).

## Experiment 4: against caveman's own baseline (Opus at xhigh)

Experiment 3 measured caveman against Sonnet. Caveman measures itself against Opus 5.5 at xhigh
effort, so experiment 4 repeats the same 14 tasks from that starting point, 1 trial per task and arm:

| Arm | Command | $ per session |
|---|---|---:|
| A. opus-xhigh | `claude --model opus --effort xhigh` | 1.03 |
| B. caveman, Opus xhigh kept | `caveman wrap claude --model opus --effort xhigh` | 0.87 |
| C. caveman with Auto | `caveman wrap claude --model caveman-auto[1m]` | 0.51 |

| Comparison | Cost | Output tokens | Turns |
|---|---|---|---|
| **C vs A** (caveman's claim) | **−48.6%** [−56.4, −39.5] | −60.7% [−66.7, −53.6] | −42.7% [−54.2, −28.3] |
| B vs A (the tool alone) | −13.4% [−27.9, +4.0] | **−22.7%** [−37.3, −4.6] | +2.8% [−24.7, +40.6] |
| C vs B (Auto alone) | −40.7% [−47.6, −32.9] | −49.2% [−55.6, −41.8] | −44.3% [−59.1, −24.1] |

All 42 sessions passed 100% of the hidden tests.

- **Caveman's claim holds against its own baseline.** With Auto, cost fell by about half, close to
  the 0.46× in caveman's benchmark, with no measurable loss of quality.
- **Auto did it by lowering the effort, not the model.** Auto sent essentially every request to
  Opus 5.5 again (Sonnet only for tiny routing requests). The saving is fewer turns and much less
  output and thinking: the same model, thinking less. This matches caveman's own note that "most
  of the saving comes from lower effort".
- **The tool alone helps a little on Opus, unlike on Sonnet.** With Opus xhigh fixed, caveman
  cut output tokens by 23% (thinking tokens by about a quarter) and cost by 13%, an interval that
  just includes 0; on code tasks alone −25% [−41, −4]. Compression again saved nothing. On Opus,
  output and thinking are a larger, pricier share of the bill, so shorter output matters more than on Sonnet.
- **Cost check:** on the caveman arm, caveman's own records match Claude Code's to within 1%.

## What this means

1. **Where you start decides whether caveman saves.** On Sonnet it cost 4–8% more, and Auto 3×
   more; on Opus at xhigh it cost 13% less, and Auto half. Same tool, opposite results.
2. **The big lever is model and effort, not talking less.** The two large effects in 240 sessions
   (3× and half) both came from Auto changing the model or its effort. Compression never triggered.
3. **Talking less pays only where output is expensive.** On Sonnet, prose is a small, cheap share of
   a coding session; on Opus at xhigh, output and thinking cost enough for caveman's voice to show.
4. **Every line in CLAUDE.md, and every tool definition, is paid on every turn.** On a cheap model
   that overhead can outweigh the saving.
5. **Check what a saving is measured against.** Caveman's 54% is real against Opus at xhigh; for a
   Sonnet user the same setting is an upgrade, not a saving.

## Limits

- One app, one language, a Pro/Max login. API-key billing, chat-heavy work, or large noisy tool output
  (where caveman's compression applies) may give different results.
- Experiment 4 and the Auto arm of experiment 3 have 1 trial per task: enough for the large effects
  (3×, half), not to pin down the smaller ones (B vs A).
- The hidden tests hit a ceiling (100% everywhere): they show that no arm lost quality, but cannot rank the arms.
- `total_cost_usd` is an API-price estimate on a subscription, not an invoice.

## Data

| | Results | Raw data |
|---|---|---|
| Exp 1 | `results/RESULTS.md` | `results/run-1/`, branches `baseline` and `caveman` |
| Exp 2 | `results/exp2/RESULTS.md` | `results/exp2/trials.jsonl`, `results/exp2/raw/` |
| Exp 3 | `results/exp3/RESULTS.md` | `results/exp3/trials.jsonl`, `results/exp3/raw/` |
| Exp 4 | `results/exp4/RESULTS.md` | `results/exp4/trials.jsonl`, `results/exp4/raw/` |

Each session's raw folder holds Claude Code's JSON, the final answer, the code change (`.patch`)
and the test logs.
