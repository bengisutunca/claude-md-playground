# Does the caveman CLAUDE.md make Claude Code cheaper?

**Short answer: no.** On a Swift/SwiftUI MVVM app built with Claude Code (Sonnet), adding the
[caveman](https://github.com/JuliusBrussee/caveman) rules (v4.0.1 skill text) as `CLAUDE.md`
made the agent's chat messages about 22% shorter, with no loss of quality, but did not lower
the cost of the work. Total cost was 3.8% *higher*, and the 95% confidence interval
(−1.0% to +8.9%) rules out any saving larger than about 1%.

## Setup

- **App:** TMDB movie browser, Swift Package, iOS 17+, MVVM, Swift Testing. Tests use JSON
  fixtures, never the network.
- **Arms:** `baseline` (no CLAUDE.md) and `caveman` (CLAUDE.md = caveman skill rules). Same prompts,
  model, tool permissions and settings; user-level settings and plugins excluded.
- **Measurement:** headless `claude -p --output-format json`, one fresh session per task.
  Cost is Claude Code's `total_cost_usd` (API-price estimate).

| | Experiment 1: chained | Experiment 2: checkpoint |
|---|---|---|
| Design | each arm builds the app step by step on its own branch | each task starts from the same reference commit in both arms |
| Tasks | 8 build steps | 8 build steps, 3 seeded bug fixes, 3 explain/review questions |
| Repetitions | 1 | 3 per task and arm (84 sessions) |
| Quality | the agent's own tests | hidden acceptance tests the agent never sees (53 tests) |

## Results (experiment 2)

Caveman vs baseline over 42 paired trials, geometric mean with 95% confidence interval.

| Metric | All tasks | Code (01–08) | Bug fix | Explain / review |
|---|---|---|---|---|
| **Cost** | **+3.8%** [−1.0, +8.9] | +5.0% [−2.8, +13.5] | +2.5% [−5.1, +10.6] | +2.0% [−7.3, +12.2] |
| Output tokens | −1.5% [−7.8, +5.2] | +2.0% [−8.1, +13.2] | −2.8% [−10.8, +5.9] | −9.1% [−21.0, +4.5] |
| Turns | −3.4% [−9.2, +2.8] | −2.3% [−12.0, +8.4] | −2.3% [−11.6, +7.9] | −7.2% [−15.3, +1.8] |
| **Final message words** | **−22.1%** [−26.3, −17.6] | −19.7% [−25.3, −13.7] | −28.8% [−40.3, −15.0] | −21.2% [−29.2, −12.3] |
| Cache write tokens | +8.9% [+4.3, +13.6] | +8.1% [+1.8, +14.6] | +8.1% [−2.5, +20.0] | +11.8% [−0.5, +25.7] |
| Hidden acceptance tests | 100% vs 100% | 100% vs 100% | 100% vs 100% | – |

Bold rows are the two clear findings: shorter messages, no cheaper work.

Experiment 1 (chained, 1 run) agrees: caveman +2.7% cost in total, every step's tests passing in both arms.

## Why the shorter messages do not save money

1. **Chat prose is a small part of a coding session.** Most output tokens are code written
   through tools. Caveman's rules explicitly leave code, comments and files untouched, so total
   output tokens did not move (−1.5%).
2. **Most of the cost is input, not output.** The agent reads files, tool results and the
   growing conversation on every turn; those are input and cache tokens.
3. **The rules themselves cost tokens.** The CLAUDE.md adds about 1.2k tokens to the context of
   every session, which shows up as +9% cache writes.

Where output *is* prose (explain/review), caveman cut answer length by about 21% and
output tokens by about 9%, but those tasks are dominated by reading code, so cost stayed flat.

## Limits

- One model (Sonnet), one app, one language. Results may differ for chat-heavy work, other models,
  or when output tokens dominate the bill.
- Only caveman's "say less" rules were tested, as a CLAUDE.md. Its other parts (proxy that
  compresses tool output, model routing) were not.
- Quality hit a ceiling: both arms passed 100% of the hidden tests, so the tests show caveman
  did not hurt quality, but cannot rank the arms.
- `total_cost_usd` is an API-price estimate on a Pro/Max subscription, not a bill.

## Data

- `results/exp2/RESULTS.md` (per-task tables), `results/exp2/trials.jsonl` (one line per session),
  `results/exp2/raw/` (each session's JSON, final answer, patch and test logs).
- `results/RESULTS.md` and `results/run-1/` for experiment 1; branches `baseline` and `caveman`
  hold its code, one commit per step.
