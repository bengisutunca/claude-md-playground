Fixed. Nothing is committed.

**Cause:** In `Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`, the check that decides when to load the next page compared the visible row's position against `movies.count + 3`. A row's position is always less than `movies.count`, so the check could never pass. `loadNextPageIfNeeded` returned early every time and page 2 was never requested. The network and service layers were fine; the bug was only in this view model.

**Fix:** I changed `+ 3` to `- 3`. That one character is the whole change. Now, as soon as one of the last 3 movies shown appears on screen, the next page starts loading, which is what the doc comment ("at (or near) the end") describes.

**Proof:**
- Before the fix, 3 existing tests in `MovieListViewModelTests` were already failing: `paginationAppendsPage2AndStopsAtEnd`, `refreshResetsPages` and `paginationErrorKeepsLoadedMovies`. They pass now.
- I added a regression test, `itemsWithinLastThreeTriggerPagination`, which checks exactly where loading starts. Page 1 has 5 movies: the 4th-from-last movie must not load page 2, and the 3rd-from-last must load it (7 movies afterwards). It uses `MockMovieService` with the existing fixtures, so it makes no network calls, and I didn't change any fixture files. Under the old check that second step would never request page 2, so the test would fail. I didn't run it against the old code to confirm.
- `swift build` succeeds and `swift test` passes all 59 tests in 11 suites.