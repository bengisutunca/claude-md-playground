Scrolling to the bottom of the Popular tab now loads the next page. `swift build` succeeds, and `swift test` passes all 59 tests.

**Cause:** In `MovieListViewModel.loadNextPageIfNeeded` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`), the check for being near the end of the list was `index >= movies.count + 3`. An item's index is always below `movies.count`, so that was never true and page 2 was never requested.

**Fix:** I changed it to `movies.count - 3`. The next page now loads when one of the last three loaded movies appears.

**Regression test:** `itemNearEndTriggersPagination` in `MovieListViewModelTests.swift` uses the mock service, so it never touches the network.
- An item four from the end does not trigger a load.
- An item three from the end does trigger a load of page 2.

I did not commit anything, and I did not touch `Tests/TMDBAppTests/Fixtures/`.