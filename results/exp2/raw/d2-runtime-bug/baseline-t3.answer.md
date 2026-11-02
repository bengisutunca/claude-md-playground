The detail screen showed "2h 4m" because of a typo in `MovieDetailContent.formatRuntime(minutes:)`. The minutes were computed as `minutes % 6` instead of `minutes % 60`. For 148 minutes that gives 4 instead of 28.

The fix is that one character, in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift:24`.

I added a regression test, `inceptionRuntimeIsNotMisformatted`, in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks that 148 gives "2h 28m" and 125 gives "2h 5m". It calls the formatter directly, so there's no network access.

`swift build` succeeds and `swift test` passes all 59 tests. Nothing is committed, and I didn't touch the fixtures.