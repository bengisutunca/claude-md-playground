Cause: `loadNextPageIfNeeded` in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47` checked `index >= movies.count + 3`. No index can satisfy that, so page 2 was never requested. The fix is `movies.count - 3`.

I added a regression test, `itemNearEndTriggersPagination`, in `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It uses the mock service, so it never hits the network. It checks two cases:
- **Second item of 5:** no fetch.
- **Third-from-last item:** page 2 is fetched, giving 7 movies.

`swift build` succeeds and `swift test` passes all 59 tests. Nothing is committed, and `Fixtures/` is untouched.