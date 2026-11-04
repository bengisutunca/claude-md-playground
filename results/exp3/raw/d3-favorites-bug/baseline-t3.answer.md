Favorites now survive a relaunch. `swift build` succeeds and `swift test` passes all 59 tests. I didn't run the app itself.

**Cause:** the `deduplicated` helper in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift`) had an inverted filter: `!seen.insert($0.id).inserted`. It kept only repeated ids and dropped the first occurrence of every movie. So `save` wrote an empty list for ordinary favorites, and `load` returned `[]` after a restart.

**Fix:** I removed the stray `!`, which is a one-character change.

**Regression test:** I added `storeRoundTripKeepsDistinctMovies` to `Tests/TMDBAppTests/FavoritesTests.swift`. It saves three distinct movies, then loads them through a fresh store on the same isolated `UserDefaults` suite, as a relaunch would. It uses only the local fixtures, so it never touches the network. I didn't run it against the unfixed code, so I haven't confirmed it fails there.

Nothing is committed, and I didn't touch `Tests/TMDBAppTests/Fixtures/`.