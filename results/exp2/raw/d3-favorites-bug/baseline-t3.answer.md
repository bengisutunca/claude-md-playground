Fixed the bug and verified: `swift build` succeeds and `swift test` passes (59 tests).

**Cause:** `UserDefaultsFavoritesStore.deduplicated` in `Sources/TMDBApp/Services/FavoritesStore.swift` had an inverted filter, `!seen.insert($0.id).inserted`. That keeps only repeated ids and drops the first occurrence of each movie. Both `save` and `load` use it, so a list of distinct favorites was written and read back as empty.

**Fix:** I removed the `!`, so the filter keeps the first occurrence of each id.

**Regression test:** I added `storeRoundTripKeepsDistinctMovies` to `Tests/TMDBAppTests/FavoritesTests.swift`. It saves three distinct movies and loads them through a fresh store instance, which stands in for a relaunch. It uses an isolated `UserDefaults` suite and fixture data, so it never touches the network.

I didn't run the new test against the unfixed code, so I haven't seen it fail there. Nothing is committed, and I didn't touch `Fixtures/`.