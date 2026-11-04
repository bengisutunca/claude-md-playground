`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) is a `@MainActor @Observable` class. It gets movies from `MovieService.popular(page:)` and publishes `state: ViewState<[Movie]>`, `paginationError` and `isLoadingNextPage`.

**First load**
- `load()` returns immediately if a fetch is in flight (`isFetching`) or if a page has already loaded (`currentPage != 0`).
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` does three things:
  - It appends the results, skipping any whose `id` is already loaded.
  - It records `currentPage` and `totalPages` from the response.
  - It sets `state` to `.empty` or `.loaded(movies)`.

**Next page**
- A view calls `loadNextPageIfNeeded(currentItem:)` as each row appears.
- It proceeds only if all of these hold:
  - No fetch is running.
  - `canLoadMore` is true (`currentPage < totalPages`).
  - The first page has loaded.
  - The item is in `movies` and is within the last 3 items (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.

**Refresh**
- `refresh()` increments `generation`, which invalidates any request still in flight.
- It also clears `isLoadingNextPage` and `paginationError`.
- It sets `state = .loading` only if there are no movies yet, so the list stays visible during a pull-to-refresh.
- It then calls `fetch(page: 1, replacing: true)`. On success this empties `movies` before appending, so the old list is replaced only once the new page arrives.
- `refresh()` has no `isFetching` guard, so it always starts a request.

**Duplicates and stale requests**
- **Duplicate triggers:** `isFetching` stops `load()` and `loadNextPageIfNeeded` from starting a second request. Because `refresh()` ignores it, a refresh can overlap an older request.
- **Stale results:** `fetch` copies `generation` into a local `token`.
  - After the `await`, a token that no longer matches means a refresh happened, and the result is discarded without touching state.
  - The `defer` resets `isFetching` and `isLoadingNextPage` only when the token still matches. The newer refresh request then owns those flags.
- **Duplicate movies:** results are filtered against the set of ids already loaded. This covers pages that overlap because the list shifted between requests.

**Errors**
- `CancellationError` is swallowed: `fetch` just returns and leaves state unchanged.
- Any other error from a stale request is ignored, using the same token check.
- Otherwise the message comes from `error.userMessage`.
  - If no movies are loaded, `state = .failed(message)`, which is a full-screen error. A later `load()` can retry, because `currentPage` is still 0.
  - If movies are loaded, the list stays on screen and only `paginationError` is set.
- Retrying a failed next page happens naturally. `paginationError` is cleared and the fetch retried the next time `loadNextPageIfNeeded` passes its guards.
- A failed refresh on an existing list shows the pagination-style error rather than wiping the list.
  - `movies` is only cleared on success, so the old data remains.
  - A failed refresh when the list was empty gives `.failed`.

I read only this file. I didn't check `ViewState`, `MovieService` or the views that call these methods.