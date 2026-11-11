I fixed the Popular tab so scrolling to the bottom loads more movies again, and added a regression test. `swift build` succeeds and `swift test` passes all 59 tests.

## Cause
The bug was a sign flip in `MovieListViewModel.loadNextPageIfNeeded` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift:47`). The latest commit (`361e548 trial start`) changed one line:

```diff
- index >= movies.count - 3 else { return }
+ index >= movies.count + 3 else { return }
```

A row's position in the list is always less than `movies.count`, so the check could never pass. The function always exited early and page 2 was never requested. The networking, decoding and test data were all fine; the bug was only in the view model.

Three existing pagination tests were already failing because of this before I changed anything.

## Fix
A one-character change back to `movies.count - 3`. That restores the intended behaviour: the next page starts loading when any of the last three rows comes on screen. Nothing outside the view model changed.

## Regression test
I added `trailingRowsLoadNextPage` to `Tests/TMDBAppTests/MovieListViewModelTests.swift`. It runs once for each of the 5 rows on page 1:
- **Rows 0–1:** no extra request, and still 5 movies.
- **Rows 2–4:** page 2 is requested and the list grows to 7 movies.

The existing tests only check the first and last rows. This one checks exactly where loading starts, so it would also catch an off-by-one in the cutoff. It uses the existing mock service and test data, so there are no network calls and nothing under `Fixtures/` changed.

To check that the test really catches the bug, I briefly put the `+ 3` back and ran it alone. The three trailing-row cases failed and the two leading ones passed. Then I restored the fix.

Two files changed (`MovieListViewModel.swift`, `MovieListViewModelTests.swift`), and nothing is committed.