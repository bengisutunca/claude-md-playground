The Popular tab never loaded a second page because of a sign error in `MovieListViewModel.loadNextPageIfNeeded`. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** the guard in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift` checked `index >= movies.count + 3`. An item's index is always below `movies.count`, so no row could ever satisfy it and the next page never fired.

**Fix:** I changed that one line to `movies.count - 3`, so the next page loads once a row within the last three is shown.

**Regression test:** I added `itemNearEndTriggersPagination` to `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It loads page 1 through the mock service, which uses fixtures and not the network. It then shows the second-to-last row and expects a page 2 request and 7 movies.

I didn't commit anything or touch `Fixtures/`.