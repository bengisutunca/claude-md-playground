Scrolling to the bottom of the Popular tab now loads the next page. `swift build` succeeds and all 59 tests pass. I didn't commit anything.

**Cause:** the prefetch check in `MovieListViewModel.loadNextPageIfNeeded` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`) had a sign error. It required `index >= movies.count + 3`, but an item's index is always below `movies.count`, so the guard never passed and page 2 was never requested.

**Fix:** I changed `+ 3` to `- 3`, so the next page loads when one of the last three items appears. The fix is in the view model, which is where the bug was.

**Regression test:** I added `itemNearEndTriggersPagination` in `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It uses the mock service, so it never touches the network. It checks that the fourth-from-last item doesn't trigger a fetch and the third-from-last does, which brings the list to 7 movies.

I didn't run the unfixed code, so I haven't seen the test fail against the bug. By inspection, the unfixed guard can't pass for any item in the list.