The bug is fixed. `swift build` succeeds and `swift test` passes all 58 tests.

**Cause:** `formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24` computed the minutes part with `minutes % 6` instead of `minutes % 60`. For 148 minutes that gave 4 instead of 28, so the screen showed "2h 4m".

**Fix:** I changed `% 6` to `% 60`, which is the only edit.

**Regression test:** I didn't add one because the repo already has two that cover this case. `runtimeFormatting` in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift` includes `(148, "2h 28m")`, and `helpersFromFixture` checks `runtimeText == "2h 28m"` using the mock service, so it makes no network calls. I didn't run the suite before the fix, so I haven't seen those tests fail on the old code. By inspection, `148 % 6 = 4`, so the old code would have failed them.

I didn't commit anything and didn't touch the fixtures.