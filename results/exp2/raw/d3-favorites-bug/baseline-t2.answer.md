Fixed: favorites now survive a relaunch, and `swift build` and `swift test` both pass (59 tests).

**Cause:** the dedupe helper in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift`) had its filter inverted. `!seen.insert(id).inserted` kept only repeated ids and dropped every first occurrence. A list of distinct movies came back empty from `load()` and was saved empty by `save()`, so the Favorites tab was empty after a restart.

**Fix:** I removed the stray `!`, so the filter is now `seen.insert($0.id).inserted`. That's a one-character change in the store layer.

**Regression test:** `storeKeepsDistinctMoviesInOrder` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves `[c, a, b, c]` to an isolated `UserDefaults` suite, then loads from a fresh store instance and expects `[c, a, b]`. It uses only the existing fixtures and never touches the network.

I didn't commit anything or touch `Tests/TMDBAppTests/Fixtures/`. I didn't run the suite before the fix, so I haven't confirmed that the new test fails without it.