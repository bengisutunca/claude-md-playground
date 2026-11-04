Scrolling to the bottom of the Popular tab now loads the next page. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** the check in `loadNextPageIfNeeded` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`) was `index >= movies.count + 3`. An item's index can never be that large, so the guard always returned early and page 2 was never requested.

**Fix:** I changed `+ 3` to `- 3`. Pagination now triggers when one of the last three loaded items appears.

**Regression test:** I added `itemNearEndTriggersPagination` in `MovieListViewModelTests.swift`. It loads page 1, calls `loadNextPageIfNeeded` with the third-from-last movie, and expects a page 2 request and 7 movies. It uses the existing mock service, so it doesn't touch the network.

Nothing is committed, and I didn't touch the fixtures.