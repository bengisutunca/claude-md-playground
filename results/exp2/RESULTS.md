# Experiment 2: checkpoint mode, baseline vs caveman CLAUDE.md

Model: sonnet · up to 3 trials per task and arm · 84 sessions. Every trial starts from the same reference commit in both arms. Δ = caveman vs baseline, geometric mean over paired trials, with 95% confidence interval. A CI that includes 0 means no detectable difference.

## Effect of caveman

| Group | Cost Δ | Output tokens Δ | Turns Δ |
|---|---|---|---|
| All tasks | +3.8% [-1.0, +8.9] (n=42) | -1.5% [-7.8, +5.2] (n=42) | -3.4% [-9.2, +2.8] (n=42) |
| Code (01–08) | +5.0% [-2.8, +13.5] (n=24) | +2.0% [-8.1, +13.2] (n=24) | -2.3% [-12.0, +8.4] (n=24) |
| Bug fix (d1–d3) | +2.5% [-5.1, +10.6] (n=9) | -2.8% [-10.8, +5.9] (n=9) | -2.3% [-11.6, +7.9] (n=9) |
| Explain / review (x1–x3) | +2.0% [-7.3, +12.2] (n=9) | -9.1% [-21.0, +4.5] (n=9) | -7.2% [-15.3, +1.8] (n=9) |

## Quality

| Group | baseline acceptance | caveman acceptance | baseline own tests pass | caveman own tests pass |
|---|---:|---:|---:|---:|
| Code (01–08) | 100.0% | 100.0% | 100% | 100% |
| Bug fix (d1–d3) | 100.0% | 100.0% | 100% | 100% |

Acceptance = share of hidden acceptance tests passed (the agent never sees them).

## Per task (mean over trials)

| Task | n | baseline $ | caveman $ | Δ $ | baseline out tok | caveman out tok | baseline turns | caveman turns | quality b / c |
|---|---:|---:|---:|---|---:|---:|---:|---:|---|
| 01-models | 3 | 0.215 | 0.227 | +4.8% [-36.2, +72.1] (n=3) | 11,171 | 11,507 | 16.7 | 15.7 | 100% / 100% |
| 02-networking | 3 | 0.182 | 0.203 | +11.0% [-13.5, +42.3] (n=3) | 9,422 | 10,464 | 11.0 | 12.0 | 100% / 100% |
| 03-service | 3 | 0.191 | 0.207 | +7.5% [-28.3, +61.4] (n=3) | 9,324 | 10,156 | 14.3 | 11.0 | 100% / 100% |
| 04-movie-list | 3 | 0.169 | 0.199 | +18.1% [-6.7, +49.7] (n=3) | 8,123 | 9,768 | 12.3 | 15.0 | 100% / 100% |
| 05-search | 3 | 0.151 | 0.164 | +8.8% [-15.6, +40.3] (n=3) | 6,502 | 6,772 | 9.7 | 9.3 | 100% / 100% |
| 06-detail | 3 | 0.262 | 0.284 | +8.1% [-6.2, +24.7] (n=3) | 12,943 | 13,817 | 17.0 | 15.0 | 100% / 100% |
| 07-favorites | 3 | 0.265 | 0.201 | -24.7% [-62.3, +50.3] (n=3) | 12,032 | 8,018 | 25.7 | 21.0 | 100% / 100% |
| 08-app-shell | 3 | 0.416 | 0.468 | +13.0% [-10.3, +42.4] (n=3) | 16,980 | 18,730 | 37.0 | 46.0 | 100% / 100% |
| d1-pagination-bug | 3 | 0.095 | 0.089 | -5.9% [-13.6, +2.5] (n=3) | 1,829 | 1,818 | 8.7 | 9.0 | 100% / 100% |
| d2-runtime-bug | 3 | 0.054 | 0.061 | +12.8% [-12.4, +45.3] (n=3) | 1,404 | 1,439 | 7.0 | 7.0 | 100% / 100% |
| d3-favorites-bug | 3 | 0.079 | 0.080 | +1.3% [-12.3, +17.0] (n=3) | 1,931 | 1,732 | 9.7 | 8.7 | 100% / 100% |
| x1-explain-pagination | 3 | 0.050 | 0.058 | +15.6% [-14.9, +57.0] (n=3) | 2,022 | 1,965 | 4.0 | 4.0 | rubric 100% / 100% |
| x2-review-search | 3 | 0.075 | 0.068 | -9.2% [-15.6, -2.3] (n=3) | 3,648 | 3,003 | 4.7 | 4.0 | 788 / 603 words |
| x3-plan-genre-filter | 3 | 0.129 | 0.130 | +1.1% [-9.9, +13.4] (n=3) | 4,641 | 4,372 | 16.3 | 15.0 | 985 / 789 words |

Total spent: baseline $7.00 · caveman $7.32 (Claude Code `total_cost_usd`; an API-price estimate on a subscription).

