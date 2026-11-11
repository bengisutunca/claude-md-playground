Fixed. Inception now shows "2h 28m".

**Cause:** `MovieDetailContent.formatRuntime(minutes:)` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24` got the leftover minutes with `minutes % 6` instead of `minutes % 60`. For 148 minutes that gives 148 % 6 = 4, so it showed "2h 4m". The typo came in with the latest commit ("trial start").

**Fix:** I changed `% 6` to `% 60` in that function, which is the only place runtime text is formatted. Nothing else changed.

**Regression test:** I added `runtimeMinutesAreRemainderOfHour` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It uses Swift Testing, calls the formatter directly, and makes no network calls. It checks four runtimes that the bug would show wrongly, each in a different way:
- 148 → "2h 28m" (bug showed "2h 4m")
- 119 → "1h 59m" (bug showed "1h 5m")
- 66 → "1h 6m" (bug showed "1h")
- 150 → "2h 30m" (bug showed "2h")

**Proof:**
- Before the fix, three existing tests failed on this bug: the Inception value, `59 → "59m"` (it gave "5m"), and the fixture-based `runtimeText`. I watched the new test's cases fail the same way only for 148; for the other three I worked out what the bug would produce rather than running them against it.
- After the fix, `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

I didn't touch the fixtures and didn't commit anything.