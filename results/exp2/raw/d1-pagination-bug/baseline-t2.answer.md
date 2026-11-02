I fixed the bug. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** in `MovieListViewModel.loadNextPageIfNeeded`, the "near the end" check was `index >= movies.count + 3`. An index is always smaller than the count, so the guard always returned early and page 2 was never requested.

**Fix:** I changed `+ 3` to `- 3` in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`. Scrolling to any of the last three rows now loads the next page.

**Regression test:** I added `itemNearEndTriggersNextPage` in `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It uses the mock service, so it never hits the network. It scrolls to the third-from-last row and checks that page 2 is requested and the list grows from 5 to 7 movies. I didn't run it against the old code to confirm it fails there, but with `+ 3` that row could never trigger a load.

I didn't commit anything or touch `Fixtures/`.