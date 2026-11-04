Favorites now survive a relaunch. `swift build` succeeds and all 59 tests pass. Nothing is committed.

**Cause:** the duplicate-removal helper in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift`) had its condition inverted. It was `filter { !seen.insert($0.id).inserted }`, which keeps only repeated ids and drops every first occurrence. Every `save` and `load` therefore produced an empty list, whatever had been favorited.

**Fix:** I removed the `!`, so the filter now keeps the first occurrence of each id.

**Regression test:** `saveThenLoadKeepsUniqueMovies` in `Tests/TMDBAppTests/FavoritesTests.swift` saves three movies, loads them back, and checks that a second store on the same `UserDefaults` (a simulated relaunch) still sees all three. It uses an isolated `UserDefaults` suite and the existing fixtures, so it never touches the network. I didn't run it against the old code to confirm it fails there.