`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) runs all popular-movie paging through one private `fetch(page:replacing:)` method. Two flags keep requests from piling up: `isFetching` allows one request at a time, and a `generation` counter lets a refresh make older requests obsolete.

## State it keeps

- **Shown to the view:** `state: ViewState<[Movie]>` (`idle` / `loading` / `loaded` / `empty` / `failed`), `isLoadingNextPage`, and `paginationError`.
- **Private bookkeeping:** `movies`, `currentPage` (0 means nothing has loaded yet), `totalPages`, `isFetching`, and `generation`.
- **Who owns it:** `RootView` creates the view model once and keeps it in `@State`, so it survives tab switches. `MovieListView` drives it.

## First load

`MovieListView` calls `.task { await viewModel.load() }` (`MovieListView.swift:16`).

- `load()` only runs if `!isFetching` and `currentPage == 0`. Otherwise it does nothing.
- If it runs, it sets `state = .loading` (the view shows `LoadingView`) and calls `fetch(page: 1)`.
- `.task` runs again every time the view reappears, for example after a tab switch. The `currentPage == 0` check makes that harmless once page 1 has loaded.

## What triggers the next page

Each row in the `.loaded` list has its own `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }` (`MovieListView.swift:35`). The list is lazy, so that task runs as each row scrolls into view.

`loadNextPageIfNeeded` only fetches when all of these are true:
- no request is in flight (`!isFetching`);
- there are more pages (`canLoadMore`, i.e. `currentPage < totalPages`);
- the first page has loaded (`currentPage > 0`);
- the row is one of the last 3 in `movies`.

When they are, it sets `isLoadingNextPage = true`, which shows a `ProgressView` in the list footer. It also clears `paginationError` and fetches `currentPage + 1`. On success, `currentPage` and `totalPages` come from the response (`PagedResponse`). On the last page `canLoadMore` becomes false and paging stops.

## How refresh works

Three things call `refresh()`:
- pull-to-refresh (`.refreshable` on the `List`);
- the Retry button on the full-screen `ErrorView`;
- the Retry button in the list footer.

`refresh()` does this:
1. Adds 1 to `generation`. Any request still in flight is now out of date.
2. Clears `isLoadingNextPage` and `paginationError`.
3. Sets `.loading` only if `movies` is empty. If movies are already showing, the list stays on screen under the pull-to-refresh spinner.
4. Calls `fetch(page: 1, replacing: true)`.

Unlike `load()`, `refresh()` does not check `isFetching`; it is meant to override whatever is running. The old movies are only cleared (`if replacing { movies = [] }`) after the new response arrives, so the list never flashes empty.

## Duplicate and stale requests

- **One request at a time:** `isFetching` blocks a second `load()` or page load while one is running. The class is `@MainActor`, so `fetch` sets the flag before its first `await` and nothing can slip in between the check and the set. The `duplicateCallsWhileLoadingAreIgnored` test covers this.
- **Stale responses:** `fetch` saves `generation` in a local `token` before calling `service.popular(page:)`. If a refresh happened in the meantime, both the success and error paths return early, so an old page can't land in a refreshed list.
- **Flags:** the `defer` only resets `isFetching` and `isLoadingNextPage` if `token == generation`. An old request finishing can't switch off the flags of the newer one.
- **Duplicate movies:** results are filtered against the ids already in `movies`. TMDB's popular ranking can shift between page requests, so a movie can come back on two pages. The filter keeps `ForEach` ids unique.

## Errors

- **Cancellation:** a `CancellationError` is ignored silently. Nothing about the list changes, and the `defer` still clears the flags.
- **Any other error:** it is ignored if it's out of date. Otherwise `error.userMessage` (in `APIError.swift`) turns it into text, for example 401 becomes "Invalid API key." and network failures become "Couldn't reach the server…". Then:
  - **No movies yet:** `state = .failed(message)`, and the view shows `ErrorView` with Retry, which calls `refresh()`.
  - **Movies already shown:** `paginationError = message`, and the list stays. The footer shows the message and a Retry button.

## Things worth knowing

I found these by reading the code; I didn't run anything to reproduce them.

1. **A cancelled request shows up as a connection error.** `TMDBClient.send` wraps every URLSession error in `APIError.transport` (`HTTPClient.swift:24-28`), including the "cancelled" error. So with the real service, the `catch is CancellationError` branch almost never fires. If the row that started a page load scrolls off screen, its `.task` is cancelled and the footer says "Couldn't reach the server". It recovers when the last rows scroll back into view, because `loadNextPageIfNeeded` runs again.
2. **The footer's Retry restarts from page 1.** It calls `refresh()`, not a retry of the failed page. Someone ten pages in loses everything they've loaded.
3. **A failed pull-to-refresh is reported as a paging error.** The old list and page counters stay, and the message appears in the footer.
4. **An empty first page is a dead end.** If page 1 returns no results, the state is `.empty`, and `EmptyStateView` has no refresh control or button. `load()` won't run again either, because `currentPage` is now 1.
5. **Paging can stall.** If a whole page is duplicates, no new rows are added, so no new row `.task` runs. Paging stays stuck until the last rows scroll out of view and back in.

The intended behaviour is covered in `Tests/TMDBAppTests/MovieListViewModelTests.swift`: first load, paging and stopping at the last page, ignoring duplicate calls, the error state, retrying, keeping movies after a paging error, and refresh resetting pages. None of the five points above has a test.