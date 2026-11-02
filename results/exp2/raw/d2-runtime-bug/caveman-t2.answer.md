Cause: `formatRuntime` in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift` computed minutes as `minutes % 6`. For 148 that gives 4, so "2h 4m". Fix: `minutes % 60`.

Regression test `inceptionRuntimeIs2h28m` added in `Tests/TMDBAppTests/MovieDetailViewModelTests.swift`. It checks 148 → "2h 28m" and 179 → "2h 59m". It calls the formatter directly, so it makes no network calls.

`swift build` succeeds. `swift test` passes all 59 tests. Nothing committed, and I didn't touch `Fixtures/`.