Favorites are now saved correctly and come back after a relaunch. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** the most recent commit (`96144bc`) flipped the duplicate-removal check in `UserDefaultsFavoritesStore` (`Sources/TMDBApp/Services/FavoritesStore.swift:43`). It used `!seen.insert($0.id).inserted`, which keeps only the *repeat* copies of a movie and throws away the first ones. Since a normal favorites list has no repeats, every save wrote an empty list. During a session everything looked fine because the view model keeps its own copy in memory, but after a relaunch `load()` read back nothing.

**Fix:** I removed the `!`, so each movie is kept once, at its first position. That one-character change in the storage layer is the whole fix.

**Regression test:** I added `storeSurvivesRelaunch()` to `Tests/TMDBAppTests/FavoritesTests.swift`. It saves `[a, b, a, c]` through one store, then loads through a new store on the same `UserDefaults` to stand in for a relaunch, and expects `[a, b, c]`. That checks both that favorites survive a restart and that duplicates are dropped in order. I didn't run it against the old code, but by the logic above it would fail there: the old version would load just `[a]`. The existing `persistsAcrossStoreInstances` test was already failing before the fix and passes now.

The test uses a separate `UserDefaults` suite that is cleaned up afterwards and makes no network calls. I didn't touch the fixtures and didn't commit anything.