The detail screen now shows Inception's 148 minutes as "2h 28m". `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** `MovieDetailContent.formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift` computed the leftover minutes with `minutes % 6` instead of `% 60`. For 148 minutes that gave 4, hence "2h 4m".

**Fix:** I changed it to `minutes % 60`, which is the only change under `Sources/`.

**Regression test:** I added `inceptionRuntimeIsNotMisformatted` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks that 148 minutes gives "2h 28m" and 90 minutes gives "1h 30m". The existing `runtimeFormatting` test already had a 148 → "2h 28m" case, so it would have caught this bug before the fix.

I made no commits and didn't touch the fixtures.