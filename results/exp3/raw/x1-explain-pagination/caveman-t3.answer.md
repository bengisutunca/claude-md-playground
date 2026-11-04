`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is a `@MainActor @Observable` class that talks to a `MovieService` and publishes a `ViewState<[Movie]>`. I read only this file, so I haven't checked `MovieService`, `ViewState` or `error.userMessage`.

**First load: `load()`**
- It does nothing if `isFetching` is true or `currentPage != 0`, so repeated calls such as `.task` firing twice are harmless.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results, stores `currentPage` and `totalPages` from the response, and sets `state` to `.empty` or `.loaded(movies)`.

**Next page: `loadNextPageIfNeeded(currentItem:)`**
- A row in the view calls it as it appears. It proceeds only if all of these hold:
  - No fetch is in flight.
  - `canLoadMore` is true (`currentPage < totalPages`).
  - The first page has loaded (`currentPage > 0`).
  - The item is found in `movies` and sits within the last 3 items.
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.

**Refresh: `refresh()`**
- It increments `generation`, which invalidates any request already in flight.
- It resets `isLoadingNextPage` and `paginationError`.
- It sets `state = .loading` only if no movies are loaded. Otherwise the existing list stays visible while it reloads.
- It calls `fetch(page: 1, replacing: true)`. The list is cleared only when the new response arrives, so a failed refresh doesn't wipe the screen.
- `refresh()` does not check `isFetching`. A refresh can start while another fetch is running, and the generation token handles that.

**Duplicate and stale requests**
- **Duplicate requests:** the `isFetching` guard in `load()` and `loadNextPageIfNeeded` prevents concurrent loads and double page fetches.
- **Stale responses:** `fetch` captures `generation` as a token. After the `await`, a mismatched token means a refresh has superseded the request, so the result is dropped, whether it was a success or a failure.
- **Flag cleanup:** the `defer` resets `isFetching` and `isLoadingNextPage` only if the token still matches. A stale request therefore can't clear the flags of the newer request.
- **Duplicate movies:** results are filtered against the IDs already in `movies`, so overlapping pages don't produce repeats.

**Errors**
- **`CancellationError`:** it is swallowed silently. No state changes, and `defer` still resets the flags if the token matches.
- **Other errors, no movies loaded:** `state = .failed(message)`, a full-screen error.
- **Other errors, movies already loaded:** only `paginationError` is set. The list stays visible and `state` remains `.loaded`. This covers a failed next page and a failed refresh over existing content.
- **Retry:** `paginationError` is cleared when the next page is requested or on refresh. Nothing here retries automatically.
- **Retrying a failed first load:** `currentPage` is still 0, so calling `load()` again works. `refresh()` also works.

**Gap:** if a refresh supersedes an in-flight request, the old request's `defer` skips resetting `isFetching`. The refresh's own `defer` resets it when it finishes. Until then, `isFetching` stays true, which blocks `load()` and `loadNextPageIfNeeded`. That is intentional, because it prevents a next-page fetch from racing the refresh.