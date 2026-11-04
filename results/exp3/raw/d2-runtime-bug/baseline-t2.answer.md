Fixed. The detail screen now shows Inception's 148 minutes as "2h 28m".

**Cause:** `MovieDetailContent.formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24` computed the leftover minutes with `minutes % 6` instead of `% 60`. For 148 minutes that gives 4, so it showed "2h 4m".

**Fix:** I changed `% 6` to `% 60`. That one-character change is the only edit.

**Regression test:** I didn't add a new one. `runtimeFormatting` in `MovieDetailViewModelTests.swift` already has a `(148, "2h 28m")` case, and it would have failed on the buggy code. It passes now. It calls `formatRuntime` directly, so it makes no network calls.

`swift build` succeeds and `swift test` passes all 58 tests. I did not commit, and I didn't touch the fixtures.