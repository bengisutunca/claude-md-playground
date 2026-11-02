Cause: `deduplicated` in `Sources/TMDBApp/Services/FavoritesStore.swift` had an inverted filter. `!seen.insert($0.id).inserted` kept only repeat ids and dropped every first occurrence. So `save` and `load` both returned an empty list for any unique favorites.

Fix: removed the `!`, so the filter keeps first occurrences.

Regression test: `uniqueMoviesSurviveSaveAndLoad` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves 3 unique movies, then loads them through a fresh store on the same `UserDefaults` suite. It uses an isolated suite and the existing fixture, so it never touches the network.

`swift build` succeeded. `swift test` passed all 59 tests in 11 suites. I did not run the test against the old code to see it fail. Nothing is committed, and `Fixtures/` is untouched.