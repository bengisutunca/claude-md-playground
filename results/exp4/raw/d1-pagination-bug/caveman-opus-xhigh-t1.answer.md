Fixed. Popular now loads page 2 and later pages as you scroll near the bottom.

**Cause:** in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`, the check that decides when to fetch the next page was `index >= movies.count + 3`. A list index is never higher than `count - 1`, so the check never passed and only page 1 was ever fetched. The view and the service layer were fine.

**Fix:** I changed that one line to `index >= movies.count - 3`, so the next page is requested once the visible row is within the last 3 items.

**Regression test:** I added `itemNearEndTriggersPagination` in `Tests/TMDBAppTests/MovieListViewModelTests.swift`. With the 5-movie page 1 fixture, it checks the exact cut-off:
- the item at `count - 4` does not trigger a fetch;
- the item at `count - 3` requests page 2, and the list grows to 7 movies.

It uses the existing `MockMovieService`, so it never touches the real network. No fixture files were changed.

**Proof:**
- Before the fix, three existing pagination tests were already failing because of this bug (`paginationAppendsPage2AndStopsAtEnd`, `paginationErrorKeepsLoadedMovies`, `refreshResetsPages`).
- After the fix, `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.

Nothing is committed.