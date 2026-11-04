The bug was a typo in `MovieDetailContent.formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift`. It computed minutes as `minutes % 6` instead of `% 60`, so 148 gave 148 % 6 = 4, which is why you saw "2h 4m". I changed it to `% 60`, and 148 minutes now shows "2h 28m".

For the regression test, I added a `(119, "1h 59m")` case to the existing parameterized `runtimeFormatting` test in `MovieDetailViewModelTests.swift`. That test already had a `(148, "2h 28m")` case, which the bug should have failed; I didn't run the tests before fixing, so I didn't confirm that. The new case also exercises the wrong divisor.

`swift build` succeeds and `swift test` passes all 58 tests. I didn't commit or touch the fixtures.