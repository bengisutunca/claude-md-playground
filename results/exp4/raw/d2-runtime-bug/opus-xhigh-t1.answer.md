Fixed: Inception's 148-minute runtime now shows as "2h 28m". `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

**Cause:** In `MovieDetailContent.formatRuntime(minutes:)` (`Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`), the leftover minutes were calculated with `minutes % 6` instead of `minutes % 60`. For 148 minutes, that gives 148 % 6 = 4, so the screen showed "2h 4m". The typo came in with the most recent commit (`trial start`). The model decodes the runtime correctly, so the bug was only in the view-model formatting.

**Fix:** I changed `% 6` back to `% 60`. That's the only change to the app code.

**Regression test:** I added `runtimeFormattingRoundTripsEveryMinute()` to `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It formats every runtime from 0 to 1440 minutes, reads the text back, and checks two things:
- the hours and minutes add up to the original runtime
- the minutes part is always between 0 and 59

I ran it before the fix and it failed (6 min came out as "0m", for example), so it does catch this bug. The test calls the formatter directly, so it never touches the network, and I didn't change anything under `Fixtures/`.

The existing tests already caught this bug too: `runtimeFormatting` fails on the 148 and 59 cases, and `helpersFromFixture` also fails, so the suite was red before the fix. The new test checks every value, so a typo like this can't get past a few hand-picked cases. Nothing is committed.