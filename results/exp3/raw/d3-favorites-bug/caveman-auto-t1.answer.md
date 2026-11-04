Favorites now survive a relaunch. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** In `UserDefaultsFavoritesStore.deduplicated` (`Sources/TMDBApp/Services/FavoritesStore.swift`), the filter was `!seen.insert($0.id).inserted`. That keeps only movies whose id had already been seen, so it threw away every unique movie. `save` stored an empty list, and `load` returned `[]` on the next launch.

**Fix:** I removed the stray `!`, so the filter is now `seen.insert($0.id).inserted`. The change is one character, in the store where the bug was.

**Regression test:** `distinctMoviesSurviveStoreRoundTrip` in `FavoritesTests.swift` saves three distinct movies, loads them back through a new store instance, and expects the same list. It uses an isolated `UserDefaults` suite and the existing fixture, so it never touches the network. I didn't run it against the unfixed code to confirm it fails there. Nothing under `Fixtures/` was changed, and nothing is committed.