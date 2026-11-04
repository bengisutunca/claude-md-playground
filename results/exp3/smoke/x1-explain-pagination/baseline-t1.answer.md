`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor` and `@Observable`, and it talks to an injected `MovieService` through `service.popular(page:)`. `Sources/TMDBApp/Views/MovieListView.swift` drives it.

## State

- `state` is a `ViewState<[Movie]>`: `.idle`, `.loading`, `.loaded`, `.empty` or `.failed`.
- `paginationError` and `isLoadingNextPage` are separate flags that only apply to pages after the first.
- The private bookkeeping is `movies`, `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching` and `generation`.
- `canLoadMore` is `currentPage < totalPages`.

## First load

- `MovieListView` calls `viewModel.load()` from `.task`.
- `load()` returns immediately if `isFetching` is true or `currentPage != 0`. A second `.task` run, such as the view reappearing, therefore does nothing once data has loaded or while a request is in flight.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results and records `currentPage` and `totalPages` from the response. It sets `state` to `.empty` if there are no movies, or `.loaded(movies)` otherwise.

## Next page

- Each row in `MovieListView` has `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }`. This fires as rows appear.
- The method only proceeds if all of these hold:
  - nothing is fetching;
  - `canLoadMore` is true;
  - `currentPage > 0`;
  - the row's index is within the last 3 items (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`. The footer shows a `ProgressView` while this runs.

## Refresh

- The list's `.refreshable` and the error view's retry button both call `refresh()`.
- `refresh()` does four things:
  1. It increments `generation`.
  2. It clears `isLoadingNextPage` and `paginationError`.
  3. It sets `.loading` only if `movies` is empty.
  4. It calls `fetch(page: 1, replacing: true)`.
- `movies` is only cleared inside `fetch` after the response arrives. The old list therefore stays on screen during a pull-to-refresh, and a failed refresh doesn't wipe it.

## Duplicate and stale requests

- **Duplicate requests:** the `isFetching` flag guards `load()` and `loadNextPageIfNeeded`, so scrolling can't start several page fetches at once.
- **Duplicate movies:** `fetch` builds a `Set` of known IDs and filters out any result already in `movies`. This protects against overlap when TMDB's popular list shifts between pages.
- **Stale responses:**
  - `fetch` captures `let token = generation` at the start.
  - After the `await`, `guard token == generation` drops the result if a refresh happened in the meantime. The same check runs in the error path.
  - The `defer` that resets `isFetching` and `isLoadingNextPage` also only runs for the current generation. A superseded request therefore can't clear the flags of the newer one.
- `refresh()` deliberately skips the `isFetching` guard so it can override an in-flight request.

## Errors

- **Cancellation:** a `CancellationError` just returns without touching `state` or `paginationError`.
- **Other errors:** stale ones are ignored. Current ones are turned into text with `error.userMessage`, and then:
  - If `movies` is empty, `state = .failed(message)`. The view shows `ErrorView`, and its retry calls `refresh()`. Because `currentPage` is still 0, a later `load()` could also retry.
  - If movies are already loaded, `state` is left alone and `paginationError = message`. The list stays visible and the footer shows the message with a Retry button.

## Details worth knowing

- The footer's Retry button calls `refresh()`, not a retry of the failed page. After a failed page 3, Retry restarts from page 1 instead of re-requesting page 3.
- A failed pull-to-refresh with existing data also goes to `paginationError`, so it appears as the footer error.
- If the very first `load()` or an empty-list `refresh()` is cancelled, `state` stays `.loading`. Nothing resets it until something calls `load()` or `refresh()` again.