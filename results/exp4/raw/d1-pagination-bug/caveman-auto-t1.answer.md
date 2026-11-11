Scrolling to the bottom of the Popular tab now loads the next page. `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

**Cause:** In `MovieListViewModel.loadNextPageIfNeeded` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`), the check for "near the end of the list" was `index >= movies.count + 3`. A row's position is always smaller than the number of movies, so that check could never be true and page 2 was never requested. The view and the networking code were fine.

**Fix:** I changed it to `index >= movies.count - 3`, so the next page starts loading when one of the last three rows comes on screen. That was the only change to app code.

**Regression test:** I added `itemNearEndTriggersPagination` to `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It checks that the 4th-from-last movie doesn't trigger a load, and that the 3rd-from-last requests page 2, giving 7 movies in total. It uses the existing `MockMovieService` and fixtures, so it never hits the real network.

Three existing tests were already failing because of this bug (`paginationAppendsPage2AndStopsAtEnd`, `paginationErrorKeepsLoadedMovies` and `refreshResetsPages`). I confirmed they failed before the fix, and they pass now. Nothing was committed.