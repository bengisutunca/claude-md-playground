Cause: in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`, the check in `loadNextPageIfNeeded` was `index >= movies.count + 3`. An index can never reach that, so page 2 was never requested. I changed it to `movies.count - 3`, so the last three rows trigger the next page.

Regression test: `itemsNearEndTriggerPagination` in `Tests/TMDBAppTests/MovieListViewModelTests.swift`. With 5 loaded movies, the 4th-from-last row loads nothing and the 3rd-from-last row loads page 2. It uses the existing `MockMovieService`, so there is no network access.

`swift build` succeeded and `swift test` passed all 59 tests. Nothing is committed, and I didn't touch `Fixtures/`.