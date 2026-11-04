`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is a `@MainActor @Observable` class that calls `MovieService.popular(page:)`. `MovieListView` drives it.

## First load
- `MovieListView` calls `viewModel.load()` from `.task` (line 16).
- `load()` returns immediately unless `!isFetching && currentPage == 0`. A second `.task` firing, for example when the view reappears, therefore does nothing once page 1 has loaded or while a request is in flight.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results and records `currentPage` and `totalPages` from the response. It then sets `state` to `.empty` if there are no movies, or `.loaded(movies)` otherwise.

## Next page
- Each row in the view runs `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }` (line 35).
- The call only proceeds if all of these hold:
  - nothing is being fetched
  - `canLoadMore` is true (`currentPage < totalPages`)
  - `currentPage > 0`
  - the row's movie is among the last 3 items (`index >= movies.count - 3`)
- When it proceeds, it sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- The view shows a footer spinner while `isLoadingNextPage` is true.

## Refresh
- `refresh()` is called from `.refreshable` and from the error and retry buttons.
- It increments `generation`, clears `isLoadingNextPage` and `paginationError`, and sets `state = .loading` only if no movies are loaded yet. Pull-to-refresh therefore keeps the current list visible.
- It then calls `fetch(page: 1, replacing: true)`. The old list is cleared only after the new response arrives.

## Duplicate and stale requests
- **Duplicates:** the `isFetching` flag blocks `load()` and `loadNextPageIfNeeded` while a request is in flight. `refresh()` does not check it, so a refresh can start while another request is running.
- **Stale results:** `fetch` captures `generation` as a `token` before the request. After the `await`, `guard token == generation` discards the response if a refresh has happened since. The `defer` only resets `isFetching` and `isLoadingNextPage` when the token still matches. That stops an old request from clearing the flags of the newer one.
- **Duplicate movies:** results are filtered against a `Set` of known IDs before being appended, so a movie that shifts between pages is not shown twice.
- **Cancellation:** a `CancellationError` is swallowed with no state change. For example, SwiftUI cancelling a row's `.task` leaves `state` and `paginationError` untouched.

## Errors
Errors from stale requests are dropped by the same token check. For current requests:
- **No movies loaded yet** (first load, or a refresh from empty): `state = .failed(error.userMessage)`. The view shows `ErrorView`, whose retry button calls `refresh()`.
- **Movies already loaded** (a failed next page, or a failed pull-to-refresh): `state` stays `.loaded`. The message goes to `paginationError`, and the list stays visible. The view shows it in the footer with a retry that also calls `refresh()` (line 51).

A failed pull-to-refresh after a successful load does not clear the list. Since `refresh()` sets `replacing: true` but only empties `movies` on success, the old list stays and the error appears in the footer.

A failed next page doesn't retry just that page. The footer retry calls `refresh()`, which restarts from page 1.