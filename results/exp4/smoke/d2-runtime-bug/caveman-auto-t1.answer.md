Fixed. The runtime formatter was taking the remainder by 6 instead of 60, so the minutes came out wrong.

**Cause:** In `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`, `MovieDetailContent.formatRuntime` computed the minutes as `minutes % 6`. For 148 that gives 4, so the screen showed "2h 4m". I changed it to `minutes % 60`. That one line is the whole fix, and it's in the view-model helper that formats the runtime text.

**Before the fix:** I ran the tests first, and three checks that were already there failed:
- 148 minutes came out as "2h 4m"
- 59 minutes came out as "5m"
- the runtime from the test fixture also came out as "2h 4m"

**Regression test:** I added `runtimeMinutesUseRemainderOfHour` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 → "2h 28m", plus 66, 90, 179 and 36, all values the old code formatted wrong. The test calls the formatter directly, so it doesn't touch the network, and no fixture files were changed.

**Result:** `swift build` succeeds and `swift test` passes all 59 tests in 11 suites. Nothing is committed.