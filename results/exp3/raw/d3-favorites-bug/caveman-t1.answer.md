Favorites now survive a relaunch. `swift build` succeeds and `swift test` passes all 59 tests. I didn't run the app itself, and nothing is committed.

**Cause:** the duplicate-removal helper in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift:43`) had its condition inverted. `filter { !seen.insert($0.id).inserted }` keeps only repeated ids and drops the first occurrence of each movie. Distinct favorites were therefore discarded on save and again on load, so the tab came back empty.

**Fix:** I removed the `!`, so the filter now keeps the first occurrence of each id and preserves order.

**Regression test:** `storeKeepsDistinctMoviesAcrossRelaunch` in `FavoritesTests.swift` saves three distinct movies, then loads them through a fresh store on the same `UserDefaults` suite and expects all three back. It reads the fixture file and uses no network. I didn't run it against the old code to watch it fail first.