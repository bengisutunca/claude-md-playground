The bug is fixed: Inception's 148 minutes now shows as "2h 28m". `swift build` succeeds and all 59 tests pass with `swift test`.

**Cause:** in `MovieDetailContent.formatRuntime` (`Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`), the leftover minutes were worked out with `minutes % 6` instead of `minutes % 60`. For 148 minutes the hours came out right (148 / 60 = 2) but the minutes didn't (148 % 6 = 4), so it showed "2h 4m".

**Fix:** I changed `% 6` to `% 60` on that one line. Nothing else in the app changed.

**Regression test:** I added `runtimeMinutesUseModuloSixty` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 → "2h 28m" plus a few values the old code got wrong: 90 → "1h 30m", 179 → "2h 59m" and 36 → "36m". It only calls the formatting function, so it doesn't touch the network.

The existing `runtimeFormatting` and `helpersFromFixture` tests already check 148 → "2h 28m" and should have failed on the old code. That suggests the test suite wasn't being run before this change went in.

Nothing is committed, and I didn't touch any fixture files.