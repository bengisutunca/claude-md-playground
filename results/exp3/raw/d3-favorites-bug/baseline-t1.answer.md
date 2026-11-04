Favorites now survive a relaunch. `swift build` succeeds, and `swift test` passes all 59 tests.

**Cause:** the dedupe helper in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift`) had its filter inverted. It was `filter { !seen.insert($0.id).inserted }`, which keeps only repeated ids and drops every first occurrence. Every save wrote an empty list, and every load returned an empty list.

**Fix:** I removed the `!`, so the filter is now `filter { seen.insert($0.id).inserted }`. The change is one character, in the persistence layer.

**Regression test:** `storeRoundTripKeepsUniqueMovies` in `Tests/TMDBAppTests/FavoritesTests.swift` saves three distinct movies. It then loads them back from a fresh store on the same isolated `UserDefaults` suite, which stands in for a relaunch. It uses the existing fixtures and makes no network calls.

An earlier `swift test` run, before the fix, ended with `error: Exited with unexpected signal code 5`. I didn't investigate it and didn't re-run the old code to see which tests failed. The earlier tests that persist favorites, like `persistsAcrossStoreInstances`, would have been exposed to the same bug.

I haven't committed anything or touched `Tests/TMDBAppTests/Fixtures/`.