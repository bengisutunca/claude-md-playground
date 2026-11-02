Cause: the dedup filter in `UserDefaultsFavoritesStore.deduplicated` was inverted. It used `!seen.insert($0.id).inserted`, which keeps only repeat ids and drops every first-seen movie. After a relaunch, `load()` returned an empty list. `save()` had the same bug, so it wrote nothing useful either.

Fix, in `Sources/TMDBApp/Services/FavoritesStore.swift`: change the filter to `seen.insert($0.id).inserted`.

Regression test: `distinctFavoritesSurviveRelaunch` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves 3 distinct movies, then loads them through a fresh store and expects the same 3 back. It uses an isolated `UserDefaults` suite and makes no network calls.

`swift build` succeeded. `swift test` passed all 59 tests. I didn't commit or touch `Fixtures/`.