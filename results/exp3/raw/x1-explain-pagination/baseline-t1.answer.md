`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor` and `@Observable`, and it gets its data from an injected `MovieService` through `service.popular(page:)`.

**State it exposes**
- `state` is a `ViewState<[Movie]>`. It starts as `.idle` and can become `.loading`, `.loaded`, `.empty` or `.failed(message)`.
- `paginationError` is a message for when a page after the first fails.
- `isLoadingNextPage` tells the UI that a next-page request is running.
- `canLoadMore` is `currentPage < totalPages`.
- Private bookkeeping: `movies`, `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching` and `generation`.

**First load**
- `load()` returns immediately unless `!isFetching && currentPage == 0`. Calling it again after the first load, or while a request is running, does nothing.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results to `movies` and stores `currentPage` and `totalPages` from the response. It sets `state` to `.empty` if there are no movies and `.loaded(movies)` otherwise.

**Next page**
- The view calls `loadNextPageIfNeeded(currentItem:)` for the row it is showing.
- The call goes ahead only if all of these hold:
  - nothing is fetching;
  - `canLoadMore` is true;
  - `currentPage > 0`, so the first page has loaded;
  - the item is found in `movies`;
  - its index is within the last 3 items (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- Because `paginationError` is cleared on each attempt, scrolling to the end again retries a failed page.

**Refresh**
- `refresh()` increments `generation`, clears `isLoadingNextPage` and `paginationError`, and sets `state = .loading` only if `movies` is empty. If there are movies, the old list stays visible during the reload.
- It then calls `fetch(page: 1, replacing: true)`. On success this empties `movies` before adding the new results, so the old pages are replaced, not merged.
- `refresh()` has no `isFetching` guard. It can start while another request is running, and the generation counter is what handles that.

**Duplicate and stale requests**
- **Duplicate requests:** `isFetching` blocks a second `load()` or `loadNextPageIfNeeded` while one is running.
- **Stale requests:**
  - `fetch` captures `let token = generation` before the request.
  - After the `await`, `guard token == generation` drops the result if a refresh happened in the meantime. This applies to both success and error paths.
  - The `defer` resets `isFetching` and `isLoadingNextPage` only if the token still matches. A stale request therefore can't clear the flag for the newer refresh request.
- **Duplicate movies:** results are filtered against `Set(movies.map(\.id))`, so a movie already in the list is not added again. This matters when items shift between pages on the server.
- **Cancellation:** a `CancellationError` is swallowed and leaves state unchanged. For example, if the SwiftUI task is cancelled, nothing shows as an error.

**Errors**
- Other errors are converted with `error.userMessage`.
- If `movies` is empty, which happens on a failed first load or a failed refresh of an empty list, `state` becomes `.failed(message)` and the screen shows a full error.
- If `movies` is not empty, `state` stays `.loaded` and the message goes into `paginationError`. The loaded list stays visible, so the UI can show an inline retry.
- A failed refresh with existing movies doesn't clear them. `movies` is only emptied after a successful response, so the old list stays and the error shows as `paginationError`.

One consequence of the stale-request handling: if a refresh starts during a next-page fetch, the old fetch is dropped. The refresh then runs unguarded, and it resets `isFetching` when it finishes.