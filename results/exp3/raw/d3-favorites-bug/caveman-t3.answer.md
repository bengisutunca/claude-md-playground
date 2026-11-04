Favorites now survive a relaunch. `swift build` succeeds and all 59 tests pass. I didn't run the test before the fix, so I haven't seen it fail on the old code.

**Cause:** `UserDefaultsFavoritesStore.deduplicated` in `Sources/TMDBApp/Services/FavoritesStore.swift` had its filter inverted (`!seen.insert(...).inserted`). It kept only repeated ids and dropped every movie seen for the first time. Because both `save` and `load` use it, favorites were lost on write and again on read.

**Fix:** I removed the `!` so it keeps the first occurrence of each id.

**Regression test:** `storeKeepsDistinctMoviesOnReload` in `FavoritesTests.swift` saves three distinct movies and checks that a fresh store instance loads the same three. It uses an isolated `UserDefaults` suite, so it never touches the network or the fixtures.

I didn't commit anything.