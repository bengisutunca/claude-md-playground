Cause: the dedupe filter in `UserDefaultsFavoritesStore.deduplicated` was inverted. `!seen.insert($0.id).inserted` kept only repeat IDs, so `load()` and `save()` dropped every unique movie.

Fix in `Sources/TMDBApp/Services/FavoritesStore.swift`: `filter { seen.insert($0.id).inserted }`.

I added the regression test `savedFavoritesSurviveRelaunch` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves 3 distinct movies and loads them back through a fresh store. I didn't run it against the old code, so I haven't seen it fail.

`swift build` succeeds. `swift test` passes all 59 tests in 11 suites. Nothing is committed, and `Fixtures/` is untouched.