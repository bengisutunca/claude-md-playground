Favorites now persist across relaunches; it was a one-character bug in the storage code. `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

**Cause:** in `Sources/TMDBApp/Services/FavoritesStore.swift:43`, the duplicate-removal filter had its condition flipped (`!seen.insert($0.id).inserted`). Instead of keeping the first copy of each movie, it kept only the repeat copies. Since a normal favorites list has no repeats, it came out empty, both when saving and when reading back.

During a session the Favorites tab looked fine because the view model keeps its own in-memory list. On relaunch it reloads from storage, gets nothing, and shows an empty tab. The `!` came in with the latest commit (`6a9b5f1`). Before the fix, the existing tests `persistsAcrossStoreInstances` and `removalByOffsetPersists` were failing and the test run crashed with "Index out of range".

**Fix:** I removed the `!`, so each movie's first occurrence is kept in its original order. That's the only source change, and it's in the storage layer where the bug was.

**Regression test:** I added `storeKeepsFirstOccurrenceOfEachMovieAcrossRelaunch` in `Tests/TMDBAppTests/FavoritesTests.swift`. It works directly on the storage layer, using a separate, throwaway `UserDefaults` area:
- **Saving:** it saves `[a, b, a, c, b]`, then opens a fresh store on the same data (which is what a relaunch does) and expects `[a, b, c]`.
- **Loading:** it writes data that already contains duplicates, `[c, a, c, b]`, and expects `[c, a, b]`. This covers loading separately, because the bug broke both directions.

I checked that the test catches the bug: with the `!` temporarily put back, it fails on both checks. After restoring the fix, everything passes.

The test uses only local fixtures and never touches the network. Nothing under `Fixtures/` was changed and nothing was committed.