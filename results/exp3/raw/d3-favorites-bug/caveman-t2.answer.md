Favorites now survive a relaunch. `swift build` succeeds and all 59 tests pass.

**Cause:** the bug was in `UserDefaultsFavoritesStore.deduplicated` in `Sources/TMDBApp/Services/FavoritesStore.swift`. Its filter was `!seen.insert($0.id).inserted`, which keeps only repeated ids and drops every first occurrence. Every `save` and every `load` therefore discarded all unique movies, so the Favorites tab came back empty.

**Fix:** I removed the `!` from that filter. Nothing outside the store layer changed.

**Regression test:** I added `storeKeepsDistinctMoviesAcrossRelaunch` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves three distinct movies into an isolated `UserDefaults` suite, then loads them through a fresh store instance. It uses a fixture and no network. I did not touch `Fixtures/`, and nothing is committed.

I didn't run the suite before the fix, so I haven't seen the tests fail on the bug. I'd expect the existing `persistsAcrossStoreInstances` test to have caught it too.