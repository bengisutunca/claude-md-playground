Fixed. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** `MovieDetailContent.formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24` computed the minutes part with `minutes % 6` instead of `% 60`. For 148 minutes that gives 148 % 6 = 4, so the screen showed "2h 4m".

**Fix:** I changed `% 6` to `% 60`.

**Regression test:** I added `runtimeMinutesUseModulo60` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 → "2h 28m" and 179 → "2h 59m", and it calls the formatter directly, so it never touches the network. The existing parameterized test already covered 148 and would have failed before the fix.

I haven't committed anything and haven't touched `Tests/TMDBAppTests/Fixtures/`.