`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor` and `@Observable`, and it gets a `MovieService` injected.

## State it owns
- `state: ViewState<[Movie]>` starts as `.idle`. The other cases used here are `.loading`, `.loaded`, `.empty` and `.failed`.
- `paginationError` and `isLoadingNextPage` cover the next-page case.
- The private fields are `movies`, `currentPage` (0 means nothing loaded yet), `totalPages` (starts at 1), `isFetching` and `generation`.
- `canLoadMore` is `currentPage < totalPages`.

## First load
`load()` does nothing if `isFetching` is true or `currentPage != 0`. Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.

On success, `fetch` does the following:
- It appends the results to `movies`.
- It records `currentPage` and `totalPages` from the response.
- It sets `state` to `.empty` if the list is empty, or `.loaded(movies)` if not.

## Next page
`loadNextPageIfNeeded(currentItem:)` is meant to be called as each row appears. It proceeds only if all of these hold:
- No fetch is in flight.
- `canLoadMore` is true.
- `currentPage > 0`.
- `currentItem` is found in `movies`.
- Its index is within the last 3 items (`index >= movies.count - 3`).

It then sets `isLoadingNextPage = true`, clears `paginationError`, and calls `fetch(page: currentPage + 1)`. Retrying after a pagination error is the same call, because `currentPage` was not advanced.

## Refresh
`refresh()` does the following:
- It increments `generation`, which invalidates any request already in flight.
- It resets `isLoadingNextPage` and `paginationError`.
- It sets `state = .loading` only if `movies` is empty. Otherwise the old list stays visible.
- It calls `fetch(page: 1, replacing: true)`.

`refresh()` does not check `isFetching`. `movies` is cleared only when the new page 1 arrives, so a failed refresh doesn't wipe the list.

## Duplicates and stale requests
- **Concurrent calls:** `isFetching` guards `load()` and `loadNextPageIfNeeded`, so only one fetch runs at a time. `refresh()` bypasses this guard on purpose.
- **Stale results:** each `fetch` captures `generation` as a token. After the `await`, it drops the result if the token no longer matches, in both the success and error paths. Its `defer` also leaves `isFetching` and `isLoadingNextPage` alone for a stale token, so the newer request owns those flags.
- **Duplicate movies:** results are filtered against the set of IDs already in `movies`. This handles items shifting between pages on the server.
- **Cancellation:** a `CancellationError` returns silently. State is untouched, but the `defer` still runs for a current token and clears `isFetching`.

## Errors
Errors are mapped with `error.userMessage` (only for non-stale requests):
- **No movies loaded yet** (first load, or a refresh from an empty list): `state = .failed(message)`.
- **Movies already on screen** (next page, or a refresh with existing data): `paginationError = message`. The list stays visible and `state` is unchanged.

A failed refresh therefore sets `paginationError` rather than `state`, even though it wasn't a pagination request. Also, after `refresh()` bumps `generation`, a cancelled older fetch skips its `defer` cleanup. The refresh's own fetch resets the flags when it finishes.