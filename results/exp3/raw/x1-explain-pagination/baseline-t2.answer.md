`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is a `@MainActor @Observable` class that gets popular movies from a `MovieService` by calling `service.popular(page:)`.

## State

- **`state: ViewState<[Movie]>`** is one of `.idle`, `.loading`, `.loaded`, `.empty` or `.failed(message)`.
- **`paginationError`** and **`isLoadingNextPage`** are separate flags for the next-page case.
- **Private bookkeeping:**
  - `movies` is the accumulated list.
  - `currentPage` and `totalPages` track progress.
  - `isFetching` marks a request in flight.
  - `generation` is a counter used to drop stale results.

## First load

`MovieListView` calls `viewModel.load()` from `.task` at line 16. `load()` does nothing if `isFetching` is true or `currentPage != 0`, so repeated `.task` calls don't reload. Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.

On success, `fetch` does the following:
1. It appends the results, skipping any whose id is already known. This dedupes movies when pages overlap.
2. It stores `currentPage` and `totalPages` from the response.
3. It sets `state` to `.empty` if there are no movies, or `.loaded(movies)` otherwise.

## Next page

Each row in `MovieListView` runs `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }` at line 35. The call proceeds only if all of these hold:
- No fetch is in flight.
- `canLoadMore` is true (`currentPage < totalPages`).
- `currentPage > 0`.
- The row's movie is within the last 3 items (`index >= movies.count - 3`).

It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`. The view shows a footer spinner while `isLoadingNextPage` is true.

## Refresh

`refresh()` is called from `.refreshable`, from the full-screen `ErrorView` retry, and from the footer's pagination-error retry.

1. It increments `generation`, which invalidates any request already in flight.
2. It resets `isLoadingNextPage` and `paginationError`.
3. It sets `state = .loading` only if `movies` is empty. Otherwise the existing list stays visible during pull-to-refresh.
4. It calls `fetch(page: 1, replacing: true)`.

`refresh()` doesn't check `isFetching`, so it always starts a new request. The old list is cleared only when the new response arrives, so a failed refresh doesn't wipe the screen.

## Duplicate and stale requests

- **Duplicates:** `isFetching` blocks a second `load()` or `loadNextPageIfNeeded` while one is running. Movie-id filtering also guards against repeated items.
- **Stale results:** each `fetch` captures `token = generation` at the start. After the `await`, `guard token == generation` discards the result if a refresh happened in the meantime. This applies to the success path and the error path.
- **Flag reset:** the `defer` resets `isFetching` and `isLoadingNextPage` only when the token still matches. A superseded request therefore can't clear the flags of the newer one.
- **Cancellation:** a `CancellationError` returns silently, with no state change. For example, SwiftUI cancels a row's `.task` when the row disappears. In that case the `defer` still runs and clears `isFetching`.

## Errors

The error message comes from `error.userMessage`. What happens next depends on whether there are movies on screen:
- **No movies yet** (first load, or a refresh from an empty list): `state = .failed(message)`. The view shows `ErrorView` with a retry that calls `refresh()`.
- **Movies already loaded** (a failed next page or a failed refresh): `state` stays `.loaded` and only `paginationError` is set. The list stays visible and the footer shows the error with a retry that also calls `refresh()`. That retry restarts from page 1 rather than retrying the failed page.

Stale failures are ignored. If the error arrives from a superseded generation, the guard returns before anything is set.

I only read the view model and the relevant lines of `MovieListView`. I didn't open `MovieService` or `ViewState`, and I didn't run the tests in `MovieListViewModelTests.swift`.