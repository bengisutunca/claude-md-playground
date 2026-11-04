Inception's 148-minute runtime now formats as "2h 28m". `swift build` succeeds and all 58 tests pass.

**Cause:** `MovieDetailContent.formatRuntime(minutes:)` computed the minutes part as `minutes % 6` instead of `minutes % 60`. For 148 that gives 4, hence "2h 4m". The fix is that one character, in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`.

**Regression test:** The parameterized `runtimeFormatting` test already had a `(148, "2h 28m")` case, and `helpersFromFixture` checks the same string through the mock service. Both would have caught this bug. I added one more case, `(119, "1h 59m")`, in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. I didn't run the suite before the fix, so I haven't confirmed the existing 148 case failed on the old code.

Nothing is committed, and nothing under `Fixtures/` was touched.