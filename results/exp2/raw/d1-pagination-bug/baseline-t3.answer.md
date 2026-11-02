The Popular tab now loads more movies when you scroll to the bottom. `swift build` succeeds and `swift test` passes all 59 tests. I didn't commit anything.

**Cause:** `MovieListViewModel.loadNextPageIfNeeded` had a sign error in its "near the end" check, in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`. It tested `index >= movies.count + 3`, which no row can satisfy, so page 2 was never requested.

**Fix:** I changed it to `movies.count - 3`, so the next page loads when one of the last three rows appears.

**Test:** I added `itemNearEndTriggersNextPage` in `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It uses the mock service, so it never touches the network. It loads page 1, then passes the third-from-last movie to `loadNextPageIfNeeded` and checks that page 2 is requested and the list grows to 7 movies. I didn't run it against the unfixed code to confirm it fails there. I didn't touch the Fixtures directory.