Favorites now survive a relaunch. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** the `deduplicated` helper in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift`) had its filter inverted. It was `filter { !seen.insert($0.id).inserted }`, which keeps only the repeated ids and drops every first occurrence. Saving a list of unique movies therefore wrote an empty list to `UserDefaults`, and the Favorites tab was empty after a restart.

**Fix:** I removed the `!`, so the filter is now `filter { seen.insert($0.id).inserted }`.

**Regression test:** `uniqueMoviesSurviveSaveAndLoad` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves two distinct movies through one store, then loads them through a second store on the same isolated `UserDefaults` suite, to simulate a relaunch. It uses no network and no fixtures.

I didn't run the new test against the unfixed code, so I haven't seen it fail there.

I didn't commit anything and didn't touch `Fixtures/`.