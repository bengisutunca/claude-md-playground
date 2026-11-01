# Benchmark results: baseline vs caveman CLAUDE.md

Model: sonnet · runs: 1 · cost = Claude Code `total_cost_usd` (API-price estimate on a subscription).

## Summary (mean of run totals)

| Metric | baseline | caveman | Δ caveman vs baseline |
|---|---:|---:|---:|
| Cost ($) | 1.9775 | 2.0305 | +2.7% |
| Turns | 159 | 136 | -14.5% |
| Output tok | 92,281 | 95,528 | +3.5% |
| Input tok | 147 | 124 | -15.6% |
| Cache write tok | 208,126 | 222,688 | +7.0% |
| Cache read tok | 2,219,220 | 1,842,634 | -17.0% |
| Time (s) | 590 | 574 | -2.8% |
| Steps with passing tests | 8/8 | 8/8 | |

## Run 1: step by step

| Step | baseline $ | caveman $ | Δ $ | baseline out tok | caveman out tok | baseline turns | caveman turns | tests (b / c) |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| 01-models | 0.2325 | 0.2006 | -13.7% | 11,231 | 10,284 | 20 | 14 | ✅ / ✅ |
| 02-networking | 0.1739 | 0.2655 | +52.6% | 9,515 | 14,666 | 11 | 15 | ✅ / ✅ |
| 03-service | 0.1683 | 0.1789 | +6.3% | 8,477 | 8,583 | 12 | 12 | ✅ / ✅ |
| 04-movie-list | 0.2011 | 0.2252 | +12.0% | 10,051 | 10,740 | 11 | 20 | ✅ / ✅ |
| 05-search | 0.1444 | 0.1564 | +8.3% | 6,335 | 6,450 | 9 | 9 | ✅ / ✅ |
| 06-detail | 0.2633 | 0.2897 | +10.0% | 12,797 | 14,009 | 17 | 15 | ✅ / ✅ |
| 07-favorites | 0.2696 | 0.2567 | -4.8% | 11,320 | 11,696 | 30 | 17 | ✅ / ✅ |
| 08-app-shell | 0.5244 | 0.4575 | -12.7% | 22,555 | 19,100 | 49 | 34 | ✅ / ✅ |

