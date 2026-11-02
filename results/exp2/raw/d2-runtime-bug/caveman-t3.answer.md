Cause: `formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift` computed minutes with `minutes % 6`. It should be `% 60`. 148 minutes gave `148 % 6 = 4`, so "2h 4m".

Fix: changed that line to `minutes % 60`.

Test: added `inceptionRuntimeIsTwoHoursTwentyEight` in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 gives "2h 28m" and 187 gives "3h 7m". It calls the formatter directly, so there is no network. I did not touch `Fixtures/` and did not commit.

`swift build` succeeded, and `swift test` passed all 59 tests.

The existing parameterized `runtimeFormatting` test already had a 148 case, but I didn't run the suite before the fix, so I can't say whether it failed on the old code.