The Popular tab now loads more movies as you scroll. `swift build` succeeds and `swift test` passes all 59 tests. I didn't run the app or commit anything.

**Cause:** `MovieListViewModel.loadNextPageIfNeeded` had an inverted threshold: `index >= movies.count + 3` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`). An item's index is always below `movies.count`, so the condition was never true and page 2 was never requested.

**Fix:** I changed `+ 3` to `- 3`. Pagination now starts when one of the last three rows appears, which is what the code evidently intended.

**Regression test:** I added `itemNearEndTriggersPagination` to `MovieListViewModelTests.swift`. It uses the mock service, so there is no network access. It shows the fourth of five rows triggering a page-2 fetch.

I didn't run the new test against the old code. The existing `paginationAppendsPage2AndStopsAtEnd` test also triggers pagination from the last item, so it should have failed before the fix.