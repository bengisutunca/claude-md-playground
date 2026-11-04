Fixed. `formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift` computed the minutes with `minutes % 6` instead of `% 60`. For 148 minutes that gave 4, so the screen showed "2h 4m". It now gives "2h 28m".

The existing parameterised test `runtimeFormatting` already had a 148 → "2h 28m" case. I added one more case there, 119 → "1h 59m". The test doesn't touch the network or the fixtures.

`swift build` succeeds and `swift test` passes (58 tests in 11 suites). I didn't run the 148 case against the old code to watch it fail, and nothing is committed.