The Popular tab now loads the next page when you scroll near the bottom. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** `loadNextPageIfNeeded` in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift` checked `index >= movies.count + 3`. An index is always below the count, so that condition could never be true and page 2 was never requested.

**Fix:** I changed it to `movies.count - 3`, so the next page loads once one of the last three rows appears.

**Regression test:** I added `itemNearEndTriggersPagination` in `MovieListViewModelTests.swift`. It uses the mock service, so it never touches the network. It passes the third-from-last of five movies and expects page 2 to load. I didn't run it against the old code to watch it fail, but with the old condition that item could not have triggered a load.

I didn't commit anything and didn't touch the fixtures.