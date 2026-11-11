Favorites now survive a relaunch. The bug was a single inverted check in the favorites storage code, and I added a regression test. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** `Sources/TMDBApp/Services/FavoritesStore.swift:43`. Before saving or loading, `UserDefaultsFavoritesStore` removes duplicate movies. That filter had a stray `!`, so it kept only repeated movies and dropped every unique one. Saving two different favorites therefore wrote an empty list to `UserDefaults`. While the app was running, the Favorites tab still showed them because it reads from memory. On relaunch it loaded the empty list. The `!` came in with the latest commit (`0e0cbd9`).

**Fix:** I removed the `!`. Duplicates are still dropped, but now the first copy of each movie is kept and the original order is preserved. Nothing outside that one function changed.

**Regression test:** `distinctMoviesSurviveRelaunch()` in `Tests/TMDBAppTests/FavoritesTests.swift`. It saves `[b, a, c, a]` with one store, then loads with a new store on the same isolated `UserDefaults` suite, which mimics a relaunch. It expects `[b, a, c]`. It uses fixture data only and never touches the network.

**Checks:**
- Before the fix, the full test run crashed (signal 5) instead of just reporting failures. Five existing Favorites tests failed, and `persistsAcrossStoreInstances` then crashed with "Index out of range" when it read the first item of the empty result.
- I put the `!` back temporarily and confirmed the new test fails (it loads `[]`), then restored the fix.

Nothing is committed and no fixture files were changed.