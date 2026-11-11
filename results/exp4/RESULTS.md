# Experiment 4: caveman against Opus at xhigh effort

Arms: opus-xhigh, caveman-opus-xhigh, caveman-auto · 42 sessions. Baseline is caveman's own benchmark baseline, Opus 5.5 at xhigh effort. Same tasks, reference commits and hidden tests as experiments 2 and 3; no CLAUDE.md in any arm. Δ = second arm vs first, geometric mean over paired trials, 95% confidence interval. An interval that includes 0 means no detectable difference.

## caveman-opus-xhigh vs opus-xhigh

| Group | Cost Δ | Output tokens Δ | Turns Δ | Message words Δ |
|---|---|---|---|---|
| All tasks | -13.4% [-27.9, +4.0] (n=14) | -22.7% [-37.3, -4.6] (n=14) | +2.8% [-24.7, +40.6] (n=14) | -7.2% [-15.4, +1.8] (n=14) |
| Code (01–08) | -24.6% [-41.0, -3.7] (n=8) | -32.9% [-48.7, -12.1] (n=8) | -12.2% [-36.7, +21.8] (n=8) | -5.0% [-14.4, +5.4] (n=8) |
| Bug fix (d1–d3) | -4.9% [-50.3, +82.0] (n=3) | -26.1% [-60.4, +37.8] (n=3) | -8.9% [-51.2, +70.2] (n=3) | -18.9% [-50.8, +33.6] (n=3) |
| Explain / review (x1–x3) | +14.2% [-42.7, +127.9] (n=3) | +18.1% [-40.8, +135.7] (n=3) | +77.1% [-79.1, +1399.3] (n=3) | -0.1% [-37.9, +60.7] (n=3) |

## caveman-auto vs opus-xhigh

| Group | Cost Δ | Output tokens Δ | Turns Δ | Message words Δ |
|---|---|---|---|---|
| All tasks | -48.6% [-56.4, -39.5] (n=14) | -60.7% [-66.7, -53.6] (n=14) | -42.7% [-54.2, -28.3] (n=14) | -16.7% [-23.5, -9.3] (n=14) |
| Code (01–08) | -54.6% [-62.4, -45.1] (n=8) | -64.5% [-72.4, -54.4] (n=8) | -38.2% [-49.8, -24.1] (n=8) | -11.8% [-20.6, -2.1] (n=8) |
| Bug fix (d1–d3) | -28.0% [-52.7, +9.6] (n=3) | -51.8% [-70.6, -21.0] (n=3) | -38.1% [-75.8, +58.5] (n=3) | -27.7% [-51.3, +7.5] (n=3) |
| Explain / review (x1–x3) | -49.1% [-74.8, +2.7] (n=3) | -57.8% [-78.0, -19.3] (n=3) | -56.6% [-92.2, +140.9] (n=3) | -17.6% [-40.9, +14.9] (n=3) |

## caveman-auto vs caveman-opus-xhigh

| Group | Cost Δ | Output tokens Δ | Turns Δ | Message words Δ |
|---|---|---|---|---|
| All tasks | -40.7% [-47.6, -32.9] (n=14) | -49.2% [-55.6, -41.8] (n=14) | -44.3% [-59.1, -24.1] (n=14) | -10.3% [-15.1, -5.1] (n=14) |
| Code (01–08) | -39.7% [-45.5, -33.4] (n=8) | -47.1% [-50.8, -43.1] (n=8) | -29.7% [-45.1, -9.9] (n=8) | -7.2% [-12.6, -1.4] (n=8) |
| Bug fix (d1–d3) | -24.3% [-40.3, -4.1] (n=3) | -34.8% [-42.8, -25.8] (n=3) | -32.1% [-64.8, +30.8] (n=3) | -10.8% [-25.6, +7.0] (n=3) |
| Explain / review (x1–x3) | -55.5% [-70.2, -33.4] (n=3) | -64.3% [-78.5, -40.7] (n=3) | -75.5% [-92.1, -23.8] (n=3) | -17.5% [-42.5, +18.4] (n=3) |

## Quality and models

| Arm | sessions | acceptance (code + fix) | own tests pass | spend by model | $ per session |
|---|---:|---:|---:|---|---:|
| opus-xhigh | 14 | 100.0% | 100% | claude-opus-5-5 $14.37 | 1.027 |
| caveman-opus-xhigh | 14 | 100.0% | 100% | claude-opus-5-5 $12.54 | 0.869 |
| caveman-auto | 14 | 100.0% | 100% | claude-opus-5-5 $7.10, claude-sonnet-5-5 $0.00 | 0.507 |

Cost: Claude Code's `total_cost_usd` for baseline and caveman; caveman's own per-model record for caveman-auto, because Claude Code cannot price the `caveman-auto` model id. Both are API-price estimates on a subscription.
Cross-check on the caveman arm, where both sources exist: caveman's record is +0.9% [-1.1, +3.0] (n=14) vs Claude Code's.

## Per task (mean over trials)

| Task | opus-xhigh $ | caveman-opus-xhigh $ | caveman-auto $ | opus-xhigh quality | caveman-opus-xhigh quality | caveman-auto quality |
|---|---:|---:|---:|---:|---:|---:|
| 01-models | 1.197 | 1.014 | 0.592 | 100% | 100% | 100% |
| 02-networking | 1.314 | 0.774 | 0.490 | 100% | 100% | 100% |
| 03-service | 1.043 | 0.638 | 0.446 | 100% | 100% | 100% |
| 04-movie-list | 1.612 | 1.259 | 0.627 | 100% | 100% | 100% |
| 05-search | 1.512 | 0.683 | 0.482 | 100% | 100% | 100% |
| 06-detail | 1.286 | 1.310 | 0.701 | 100% | 100% | 100% |
| 07-favorites | 1.200 | 1.146 | 0.673 | 100% | 100% | 100% |
| 08-app-shell | 2.697 | 2.676 | 1.629 | 100% | 100% | 100% |
| d1-pagination-bug | 0.385 | 0.277 | 0.230 | 100% | 100% | 100% |
| d2-runtime-bug | 0.230 | 0.229 | 0.175 | 100% | 100% | 100% |
| d3-favorites-bug | 0.393 | 0.473 | 0.325 | 100% | 100% | 100% |
| x1-explain-pagination | 0.292 | 0.382 | 0.196 | rubric 100% | rubric 100% | rubric 100% |
| x2-review-search | 0.657 | 0.545 | 0.251 | 962 words | 856 words | 831 words |
| x3-plan-genre-filter | 0.551 | 0.757 | 0.283 | 1289 words | 1158 words | 913 words |

