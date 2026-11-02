`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor` and `@Observable`, and it gets a `MovieService` injected.

## State it holds
- `state: ViewState<[Movie]>` is the main UI state. It is `.idle`, `.loading`, `.loaded`, `.empty` or `.failed`.
- `paginationError` and `isLoadingNextPage` are used for the page-after-the-first case.
- Private bookkeeping is `movies`, `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching` and `generation`.
- `canLoadMore` is `currentPage < totalPages`.

## First load
`MovieListView` calls `viewModel.load()` from `.task` (line 16).
- `load()` returns immediately if a fetch is in flight or if `currentPage != 0`. That makes repeated `.task` firings harmless.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- `fetch` calls `service.popular(page:)`. It appends the results that aren't already known and stores `currentPage` and `totalPages` from the response. It then sets `state` to `.empty` if there are no movies, or `.loaded(movies)` if there are.

## Next page
The list view attaches `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }` to each row (line 35). The view model decides whether to fetch. It proceeds only if all of these hold:
- No fetch is running (`!isFetching`).
- `canLoadMore` is true.
- `currentPage > 0`, so the first page has already loaded.
- The row's movie is found in `movies` and its index is within the last 3 (`index >= movies.count - 3`).

If so, it sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`. The view shows a spinner while `isLoadingNextPage` is true. When `paginationError` is set, it shows an error row whose button calls `refresh()` (lines 45–51).

## Refresh
`refresh()` is called from `.refreshable`, from the full-screen `ErrorView` retry button, and from the pagination error row.
- It increments `generation`, resets `isLoadingNextPage` and `paginationError`, and sets `state = .loading` only if `movies` is empty. A pull-to-refresh therefore keeps the current list on screen.
- It then calls `fetch(page: 1, replacing: true)`. On success, `fetch` clears `movies` and rebuilds the list from page 1.
- `refresh()` does not check `isFetching`. It always starts a new request and supersedes any running one.

## Duplicate and stale requests
- **Duplicate triggers:** `load()` and `loadNextPageIfNeeded` are guarded by `isFetching`. `load()` is also guarded by `currentPage == 0`.
- **Duplicate items:** `fetch` filters each page's results against the set of known movie ids, so overlapping pages from the API don't produce repeated rows.
- **Stale responses:** `fetch` captures `let token = generation` before the request. After the `await`, `guard token == generation else { return }` drops the result if a refresh happened in the meantime. The `defer` only resets `isFetching` and `isLoadingNextPage` when the token still matches. An old request therefore can't clear the flags of the newer one.

## Errors
- **Cancellation:** a `CancellationError` returns silently. This happens, for example, when SwiftUI cancels a `.task`. It changes no state, and `isFetching` is reset by the `defer` if the token still matches.
- **Superseded request:** if the token no longer matches, the error is ignored.
- **Other errors:** the message comes from `error.userMessage`.
  - If `movies` is empty, `state = .failed(message)`. The full-screen `ErrorView` shows with a retry that calls `refresh()`.
  - If movies are already loaded, `state` stays `.loaded` and only `paginationError` is set. The existing list stays visible. The next-page attempt doesn't advance `currentPage`, so a retry fetches the same page again.

One consequence of the code: after a failed first page, `currentPage` is still 0. Calling `load()` again would therefore retry, and `refresh()` does too.