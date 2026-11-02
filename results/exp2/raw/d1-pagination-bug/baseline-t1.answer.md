The Popular tab now loads more movies when you scroll near the bottom. `swift build` succeeds and `swift test` passes all 59 tests.

**Cause:** the "near the end of the list" check in `MovieListViewModel.loadNextPageIfNeeded` used `index >= movies.count + 3`. An item's index is always below `movies.count`, so that condition could never be true. Page 2 was never requested.

**Fix:** I changed `+ 3` to `- 3` in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`. That is the only source change. Page 2 now loads when any of the last three rows appears.

**Regression test:** I added `itemNearEndTriggersNextPage` to `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It uses the existing mock service, so it never touches the network. It checks that the third-from-last item triggers a page-2 request and that the list grows from 5 to 7 movies. I didn't run it against the unfixed code to confirm it fails there.

I didn't commit anything or touch the fixtures.