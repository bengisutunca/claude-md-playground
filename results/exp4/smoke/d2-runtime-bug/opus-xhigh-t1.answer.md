The bug is fixed: Inception's 148 minutes now shows as "2h 28m". `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

**Cause:** a typo in the runtime formatter, `MovieDetailContent.formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`. It worked out the leftover minutes with `minutes % 6` instead of `minutes % 60`. The hours part (`148 / 60 = 2`) was right, but 148 % 6 is 4, so the screen showed "2h 4m".

**Fix:** changed `% 6` to `% 60`. It's a one-character change in the view-model, where the formatting happens. The model, decoding and view code were already correct.

**Regression test:** I added `runtimeMinutesUseModuloSixty()` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks:
- the reported case: 148 → "2h 28m";
- every value from 0 to 600 minutes: it reads the formatted text back into minutes and checks it matches the original. That catches any wrong divisor or modulus, not just this one.

It calls the formatter directly, so there's no network access, and I didn't touch `Fixtures/` or commit anything.

Two things worth knowing:
- **The existing tests already caught this.** Before the fix, `swift test` failed with 3 issues: `runtimeFormatting` for 148 and 61, and `helpersFromFixture` (Inception's fixture produced "2h 4m"). So the suite was already red, and this change turns it green.
- **I didn't run the new test against the old code.** My command to put the bug back temporarily wasn't approved. I'm confident it would fail there, because it asserts the same 148 → "2h 28m" result that the pre-fix run returned as "2h 4m".