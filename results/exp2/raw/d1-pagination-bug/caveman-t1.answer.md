Cause: the guard in `MovieListViewModel.loadNextPageIfNeeded` (`MovieListViewModel.swift:47`) used `index >= movies.count + 3`. That is never true, so page 2 was never requested.

Fix: changed it to `index >= movies.count - 3`. This is the only source change, in the view model where the bug was.

Regression test: `itemNearEndTriggersPaginationButEarlierItemDoesNot` in `MovieListViewModelTests.swift`. It checks that the 4th-from-last item loads nothing and the 3rd-from-last loads page 2. It uses `MockMovieService`, so it never touches the network.

`swift build` succeeds. `swift test` passes all 59 tests. I didn't run the app. Nothing is committed, and `Fixtures/` is untouched.