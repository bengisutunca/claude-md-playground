Fixed. Inception now shows "2h 28m".

**Cause:** in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`, `formatRuntime` worked out the leftover minutes with `minutes % 6` instead of `minutes % 60`. For 148, that gives 148 % 6 = 4, so the screen showed "2h 4m". The hours part was already right.

**Fix:** changed `% 6` to `% 60`. That one character is the only change to the app code. The bug is in the view model's formatting helper, so the fix is too; the model and the view were already correct.

**Regression test:** I added `runtimeMinutesUseSixtyMinuteRemainder` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148, 90, 179 and 66 minutes, all cases where the old bug gives a wrong answer. It calls the pure formatter directly, so it never touches the network.

**Results:** `swift build` succeeded, and `swift test` passed all 59 tests in 11 suites.

The suite already had tests expecting "2h 28m" (`runtimeFormatting` with 148, and `helpersFromFixture`), so they should have been failing before this fix. I didn't run the tests on the unfixed code to confirm that, but it's worth checking why those failures weren't noticed. Nothing was committed.