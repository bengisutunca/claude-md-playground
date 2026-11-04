The bug was a typo in `formatRuntime`, in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`. It computed the minutes part as `minutes % 6` instead of `minutes % 60`. For 148 minutes that gave 148 % 6 = 4, so the screen showed "2h 4m". I changed it to `% 60`, which gives "2h 28m".

I didn't add a new regression test, because `Tests/TMDBAppTests/MovieDetailViewModelTests.swift` already covers this case:
- **`runtimeFormatting`:** it includes `(148, "2h 28m")`.
- **`helpersFromFixture`:** it expects "2h 28m" for Inception from the mock fixture.

I did not run the tests before the fix, so I haven't seen them fail on the old code.

`swift build` succeeds and `swift test` passes all 58 tests. Nothing is committed, and I didn't touch the Fixtures directory.