# Experiment 3: the full caveman tool

Arms: baseline, caveman, caveman-auto · 98 sessions. Same tasks, reference commits and hidden tests as experiment 2; no CLAUDE.md in any arm. Δ = second arm vs first, geometric mean over paired trials, 95% confidence interval. An interval that includes 0 means no detectable difference.

## caveman vs baseline

| Group | Cost Δ | Output tokens Δ | Turns Δ | Message words Δ |
|---|---|---|---|---|
| All tasks | +8.0% [+2.9, +13.2] (n=42) | -4.5% [-9.4, +0.7] (n=42) | -7.5% [-15.9, +1.7] (n=42) | -4.1% [-8.4, +0.4] (n=42) |
| Code (01–08) | +2.9% [-3.4, +9.5] (n=24) | -7.2% [-12.8, -1.2] (n=24) | -4.4% [-15.4, +8.2] (n=24) | -3.7% [-10.2, +3.2] (n=24) |
| Bug fix (d1–d3) | +21.8% [+7.6, +38.0] (n=9) | -0.2% [-14.3, +16.2] (n=9) | +0.5% [-14.5, +18.2] (n=9) | -3.3% [-14.2, +9.0] (n=9) |
| Explain / review (x1–x3) | +8.8% [+0.7, +17.4] (n=9) | -1.2% [-15.4, +15.4] (n=9) | -22.1% [-42.2, +5.1] (n=9) | -5.9% [-13.1, +1.9] (n=9) |

## caveman-auto vs baseline

| Group | Cost Δ | Output tokens Δ | Turns Δ | Message words Δ |
|---|---|---|---|---|
| All tasks | +203.3% [+145.3, +275.0] (n=14) | +45.8% [+21.0, +75.8] (n=14) | +27.9% [-5.2, +72.5] (n=14) | +36.5% [+18.6, +57.2] (n=14) |
| Code (01–08) | +185.9% [+144.9, +233.8] (n=8) | +24.9% [+3.0, +51.5] (n=8) | +20.7% [-5.9, +55.0] (n=8) | +55.9% [+35.2, +79.8] (n=8) |
| Bug fix (d1–d3) | +146.1% [-22.8, +684.4] (n=3) | +67.6% [-6.9, +201.6] (n=3) | +51.3% [+15.2, +98.9] (n=3) | +12.9% [-47.6, +143.3] (n=3) |
| Explain / review (x1–x3) | +337.6% [+23.7, +1448.6] (n=3) | +91.7% [-37.1, +484.3] (n=3) | +26.0% [-93.1, +2200.7] (n=3) | +15.7% [-21.9, +71.4] (n=3) |

## caveman-auto vs caveman

| Group | Cost Δ | Output tokens Δ | Turns Δ | Message words Δ |
|---|---|---|---|---|
| All tasks | +162.2% [+109.4, +228.3] (n=14) | +38.4% [+13.1, +69.4] (n=14) | +29.8% [-5.0, +77.3] (n=14) | +42.2% [+26.5, +59.8] (n=14) |
| Code (01–08) | +151.6% [+123.5, +183.3] (n=8) | +18.5% [+0.4, +39.8] (n=8) | +15.5% [-6.5, +42.7] (n=8) | +50.2% [+28.6, +75.5] (n=8) |
| Bug fix (d1–d3) | +86.7% [-36.9, +452.6] (n=3) | +49.9% [-20.7, +183.4] (n=3) | +30.6% [-18.7, +109.8] (n=3) | +39.9% [-31.1, +184.0] (n=3) |
| Explain / review (x1–x3) | +311.2% [+21.6, +1290.2] (n=3) | +93.3% [-52.4, +684.9] (n=3) | +76.0% [-91.1, +3381.7] (n=3) | +24.9% [-15.9, +85.5] (n=3) |

## Quality and models

| Arm | sessions | acceptance (code + fix) | own tests pass | spend by model | $ per session |
|---|---:|---:|---:|---|---:|
| baseline | 42 | 100.0% | 100% | claude-sonnet-5-5 $7.04 | 0.168 |
| caveman | 42 | 100.0% | 100% | claude-sonnet-5-5 $7.36 | 0.175 |
| caveman-auto | 14 | 100.0% | 100% | claude-opus-5-5 $6.64, claude-sonnet-5-5 $0.11 | 0.482 |

Cost: Claude Code's `total_cost_usd` for baseline and caveman; caveman's own per-model record for caveman-auto, because Claude Code cannot price the `caveman-auto` model id. Both are API-price estimates on a subscription.
Cross-check on the caveman arm, where both sources exist: caveman's record is -0.0% [-0.0, +0.0] (n=42) vs Claude Code's.

## Per task (mean over trials)

| Task | baseline $ | caveman $ | caveman-auto $ | baseline quality | caveman quality | caveman-auto quality |
|---|---:|---:|---:|---:|---:|---:|
| 01-models | 0.197 | 0.210 | 0.610 | 100% | 100% | 100% |
| 02-networking | 0.189 | 0.195 | 0.415 | 100% | 100% | 100% |
| 03-service | 0.180 | 0.184 | 0.414 | 100% | 100% | 100% |
| 04-movie-list | 0.209 | 0.205 | 0.553 | 100% | 100% | 100% |
| 05-search | 0.149 | 0.157 | 0.358 | 100% | 100% | 100% |
| 06-detail | 0.263 | 0.288 | 0.903 | 100% | 100% | 100% |
| 07-favorites | 0.247 | 0.249 | 0.580 | 100% | 100% | 100% |
| 08-app-shell | 0.471 | 0.460 | 1.460 | 100% | 100% | 100% |
| d1-pagination-bug | 0.090 | 0.104 | 0.250 | 100% | 100% | 100% |
| d2-runtime-bug | 0.053 | 0.065 | 0.155 | 100% | 100% | 100% |
| d3-favorites-bug | 0.075 | 0.094 | 0.110 | 100% | 100% | 100% |
| x1-explain-pagination | 0.046 | 0.047 | 0.258 | rubric 100% | rubric 100% | rubric 100% |
| x2-review-search | 0.063 | 0.073 | 0.381 | 747 words | 753 words | 781 words |
| x3-plan-genre-filter | 0.114 | 0.126 | 0.303 | 925 words | 845 words | 937 words |

