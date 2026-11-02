Popular movies load in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. `MovieListView` (`Sources/TMDBApp/Views/MovieListView.swift`) drives it.

**First load**
- `MovieListView` calls `viewModel.load()` from `.task`.
- `load()` returns early if `isFetching` is set or `currentPage != 0`. A second `.task` firing after a successful load does nothing.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- `fetch` calls `service.popular(page:)` (`MovieService`). It appends the movies, stores `currentPage` and `totalPages` from the response, and sets `state` to `.loaded(movies)`, or `.empty` if there are none.

**Next page**
- Each row has `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }`, so the call fires when a row appears.
- The guard requires all of these:
  - no fetch in flight
  - `canLoadMore` (`currentPage < totalPages`)
  - `currentPage > 0`
  - the row is in `movies`
  - the row's index is in the last 3 (`index >= movies.count - 3`)
- If it passes, the view model sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- The view shows a spinner in `footer` while `isLoadingNextPage` is true.

**Refresh**
- Pull-to-refresh and the error buttons call `refresh()`.
- It increments `generation`, then clears `isLoadingNextPage` and `paginationError`.
- It sets `state = .loading` only if `movies` is empty. Otherwise the old list stays visible.
- It then calls `fetch(page: 1, replacing: true)`. The old movies are cleared only when the response arrives, so a failed refresh keeps the list.
- `refresh()` has no `isFetching` guard. It always starts, and the `generation` counter handles any request already in flight.

**Duplicate and stale requests**
- **Concurrent fetches:** the `isFetching` guard in `load()` and `loadNextPageIfNeeded` blocks them. Fast scrolling can't start the same page twice.
- **Duplicate movies:** `fetch` skips any movie whose `id` is already in `movies`. This covers TMDB shifting items between pages.
- **Stale responses:** `fetch` captures `token = generation` before the request. A response with a mismatched token is dropped, on both success and error.
- **Flag reset:** the `defer` resets `isFetching` and `isLoadingNextPage` only when the token still matches. A superseded request therefore can't clear the flags of the newer refresh.

**Errors**
- **Cancellation:** `CancellationError` is swallowed and state is untouched. After a cancelled first load, `state` stays `.loading` and `currentPage` stays 0, so the next `.task` can retry `load()`.
- **Other errors with no movies loaded:** `state = .failed(error.userMessage)`. The view shows `ErrorView`, whose retry calls `refresh()`.
- **Other errors with movies loaded:** `paginationError = message` and `state` stays `.loaded`. The list stays visible, and the `footer` shows the message and a Retry button.

**Gaps**
- The footer's Retry calls `refresh()`, so it reloads from page 1 instead of retrying the failed page.
- Only `CancellationError` is treated as a cancellation. If `service` surfaces a cancelled request as `URLError(.cancelled)`, it would appear as a normal error. I did not check the service implementation.