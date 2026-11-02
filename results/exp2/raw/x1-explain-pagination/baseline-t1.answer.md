`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor` and `@Observable`, and it fetches through an injected `MovieService` (`service.popular(page:)`). `MovieListView` drives it.

## State
- `state` is a `ViewState<[Movie]>`: `.idle`, `.loading`, `.loaded`, `.empty` or `.failed(message)`.
- `paginationError` and `isLoadingNextPage` are separate flags for the "load more" footer.
- The private bookkeeping is `movies`, `currentPage`, `totalPages`, `isFetching` and `generation`.
- `canLoadMore` is `currentPage < totalPages`.

## First load
- `MovieListView` calls `viewModel.load()` from `.task`.
- `load()` returns immediately if `isFetching` is true or `currentPage != 0`. That makes repeated `.task` firings harmless once data has loaded or a request is in flight.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results, stores `currentPage` and `totalPages` from the response, and sets `state` to `.empty` or `.loaded(movies)`.

## Next page
- Each row in `MovieListView` has `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`.
- That method only proceeds if all of these hold:
  - nothing is in flight (`!isFetching`);
  - `canLoadMore` is true;
  - `currentPage > 0`;
  - the row's movie is within the last 3 items (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- The view shows a spinner while `isLoadingNextPage` is true, or an error row when `paginationError` is set.

## Refresh
- `refresh()` is called by `.refreshable` (pull to refresh), by the full-screen `ErrorView` retry, and by the footer's retry button.
- It increments `generation`, clears `isLoadingNextPage` and `paginationError`, and sets `state = .loading` only if the list is empty. A populated list stays visible during the refresh.
- It then calls `fetch(page: 1, replacing: true)`. The old `movies` are cleared only after the new response arrives, so a failed refresh doesn't wipe the list.
- `refresh()` does not check `isFetching`. It always starts a new request and supersedes whatever was in flight.

## Duplicate and stale requests
- **Duplicate triggers:** `load()` and `loadNextPageIfNeeded` both bail out on `isFetching`. Many rows appearing at once therefore produce one page request.
- **Duplicate items:** `fetch` builds a `Set` of known IDs and filters the new page against it. Overlapping pages from the API can't create duplicate rows.
- **Stale responses:** `fetch` captures `let token = generation` before awaiting. After the await, `guard token == generation` drops the result, and the same check guards the error path. A page request that was in flight when `refresh()` ran therefore can't append old data.
- **`defer` cleanup:** it resets `isFetching` and `isLoadingNextPage` only if the token still matches. A superseded request can't clear the flag for the newer one.

## Errors
- **`CancellationError`:** `fetch` returns silently. It doesn't set an error state, but the `defer` still resets `isFetching`, so a later `load()` or `refresh()` works. If the first load is cancelled, for example when the view disappears, `state` stays `.loading` and `currentPage` stays 0, so the next `.task` retries.
- **Other errors, no movies loaded yet:** `state = .failed(error.userMessage)`. The view shows `ErrorView`, whose retry calls `refresh()`.
- **Other errors, movies already loaded:** this covers a failed next page and a failed refresh over existing data. `state` is untouched, so the list stays on screen, and `paginationError` is set so the footer shows the message.

One thing you might not expect: the footer's retry button calls `refresh()`, not a retry of the failed page. A failed page 3 therefore restarts the list from page 1.