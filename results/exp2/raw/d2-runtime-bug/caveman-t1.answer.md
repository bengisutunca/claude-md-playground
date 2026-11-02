Cause: `formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift` computed minutes as `minutes % 6`. For 148 that gives 4, so the screen showed "2h 4m".

Fix: changed it to `minutes % 60`. The bug was in the formatting helper, so I fixed it there.

Test: added `runtimeMinutesUseModulo60` in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 → "2h 28m", 90 → "1h 30m" and 179 → "2h 59m". It calls the formatter directly, so it never touches the network.

`swift build` succeeded and `swift test` passed all 59 tests. I did not commit and did not touch the fixtures.