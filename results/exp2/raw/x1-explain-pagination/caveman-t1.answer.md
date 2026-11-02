`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor @Observable` and calls `MovieService.popular(page:)`.

**First load**
- `MovieListView` calls `load()` from `.task` (line 16).
- `load()` returns early if `isFetching` is true or `currentPage != 0`. That makes repeat calls no-ops.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results and stores `currentPage` and `totalPages` from the response. It sets `state` to `.empty` if there are no movies, otherwise to `.loaded(movies)`.

**Next page**
- Each row in `MovieListView` runs `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }` (line 35).
- The call proceeds only if all of these hold:
  - `!isFetching`
  - `canLoadMore` (`currentPage < totalPages`)
  - `currentPage > 0`
  - the row's movie is among the last 3 items (`index >= movies.count - 3`)
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- The view shows a spinner while `isLoadingNextPage` is true.

**Refresh**
- `refresh()` is called by pull-to-refresh (`.refreshable`), the full-screen `ErrorView` retry button, and the pagination-error retry button.
- It increments `generation`, clears `isLoadingNextPage` and `paginationError`, and sets `state = .loading` only if `movies` is empty. A non-empty list stays visible during the refresh.
- It then calls `fetch(page: 1, replacing: true)`. `movies` is cleared only after the new response arrives, not before.
- `refresh()` does not check `isFetching`, so it always starts a new request.

**Duplicate and stale requests**
- **Duplicate triggers:** the `isFetching` guard in `load()` and `loadNextPageIfNeeded` blocks overlapping loads and pagination.
- **Stale results:** `fetch` captures `token = generation` at the start.
  - After the `await`, it drops the result if `token != generation`. This applies to both successes and errors.
  - A refresh issued during an in-flight page load therefore wins, and the old response never touches `movies`.
  - The `defer` resets `isFetching` and `isLoadingNextPage` only when the token still matches. The newer request owns those flags.
- **Duplicate movies:** before appending, `fetch` filters out any result whose `id` is already in `movies`. This covers overlap between pages.
- **Cancellation:** `CancellationError` is swallowed with a bare `return`. State is left unchanged, for example when the view's `.task` is cancelled.
  - If a request is cancelled while its token is still current, the `defer` resets `isFetching`. A later trigger can then retry.

**Errors**
- Errors are mapped with `error.userMessage`.
- If `movies` is empty, `state = .failed(message)`. The view shows `ErrorView`, and its retry calls `refresh()`.
- If movies are already loaded, `state` is untouched and `paginationError = message`. The list stays visible and the view shows an inline error with a retry button, which also calls `refresh()`. Retry therefore restarts from page 1 instead of retrying the failed page.
- `currentPage` is not advanced on failure.
- A failed refresh that follows a successful load keeps the old `movies` because replacement happens only on success. The failure goes to `paginationError`, not to `state`.