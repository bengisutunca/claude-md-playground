Fixed: Inception's 148 minutes now shows as "2h 28m".

**Cause:** `MovieDetailContent.formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24` worked out the leftover minutes as `minutes % 6` instead of `minutes % 60`. 148 % 6 = 4, so it showed "2h 4m". Any runtime with 6 or more leftover minutes was wrong; for example, 59 minutes showed as "5m".

**Fix:** I changed `% 6` to `% 60`. That one-character change is the whole fix, and it's in the formatter, where the bug was. Nothing else changed.

**Regression test:** I added `runtimeMinutesUseRemainderOfSixty` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 → "2h 28m", 90 → "1h 30m", 179 → "2h 59m" and 36 → "36m". All of these have 6 or more leftover minutes, so the old `% 6` code would fail them. The test calls the formatter directly, so it uses no network and doesn't touch the fixtures.

**Results:**
- Before the fix, `swift test` failed 3 checks: `runtimeFormatting` for 59 and 148, and `helpersFromFixture` (which got "2h 4m"). Those existing tests already caught the bug.
- After the fix, `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

Nothing is committed.