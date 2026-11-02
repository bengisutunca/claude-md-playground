Everything is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. `MovieListView` drives it.

**First load**
- `MovieListView` calls `viewModel.load()` from `.task`.
- `load()` returns early if `isFetching` is true or `currentPage != 0`. Re-appearing the view therefore does not reload.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- `fetch` calls `service.popular(page:)`, appends the results, and stores `currentPage` and `totalPages`.
- It then sets `state` to `.empty` if there are no movies, or `.loaded(movies)` otherwise.

**Next page**
- Each row runs `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }` when it appears.
- The call proceeds only if all of these hold:
  - no fetch is in flight (`!isFetching`)
  - `canLoadMore` (`currentPage < totalPages`)
  - `currentPage > 0`
  - the row's index is within the last 3 movies (`index >= movies.count - 3`)
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- The view shows a `ProgressView` footer while `isLoadingNextPage` is true.

**Refresh**
- Pull-to-refresh (`.refreshable`) and both Retry buttons call `refresh()`.
- `refresh()` does these steps:
  1. Increments `generation`.
  2. Clears `isLoadingNextPage` and `paginationError`.
  3. Sets `state = .loading` only if `movies` is empty. Otherwise the list stays visible.
  4. Calls `fetch(page: 1, replacing: true)`.
- `movies` is emptied only when the new page 1 arrives, so a failed refresh does not wipe the list.

**Duplicates and stale requests**
- **Concurrent fetches:** `isFetching` blocks a second `load()` or next-page call while one is in flight. `refresh()` has no such guard, so it can start while another fetch is running.
- **Stale results:** `fetch` captures `generation` as `token` before the request. After the `await`, a mismatch means a refresh superseded it, and the result or error is dropped.
- **Stale cleanup:** the `defer` that resets `isFetching` and `isLoadingNextPage` runs only if the token still matches. The newer fetch resets them itself.
- **Duplicate items:** new results are filtered against `Set(movies.map(\.id))`, so overlapping pages never add the same movie twice.
- **Cancellation:** `CancellationError` returns silently. The token still matches, so the `defer` clears the flags.

**Errors**
- **Error on page 1 with no movies:** `state = .failed(error.userMessage)`. The view shows `ErrorView`, and its retry calls `refresh()`.
- **Error with movies already loaded** (next page or refresh): `state` stays `.loaded` and `paginationError` is set. The footer shows the message and a Retry button.
- **No auto-retry:** the next page loads again only when a row re-appears (for example after scrolling) or the user taps Retry.

**Gaps**
- The footer Retry calls `refresh()`, so it reloads from page 1 and does not retry the failed page.
- If a refresh is cancelled while `movies` is empty, `state` stays `.loading`. The code does not reset it, because the `CancellationError` branch just returns.
- A `URLError.cancelled` is not a `CancellationError`. It goes through the generic error path and shows a message.