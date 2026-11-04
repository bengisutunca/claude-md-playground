`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) is a `@MainActor @Observable` class. It fetches pages through an injected `MovieService`, using `service.popular(page:)`.

**State it keeps**
- `state: ViewState<[Movie]>` is what the UI renders. It is one of `.idle`, `.loading`, `.loaded`, `.empty` or `.failed`.
- `paginationError` and `isLoadingNextPage` are separate flags for page 2 and later.
- Private fields: `movies`, `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching` and `generation`.
- `canLoadMore` is `currentPage < totalPages`.

**First load: `load()`**
- It returns immediately unless `!isFetching && currentPage == 0`, so a second call after a successful load, or during a load, does nothing.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results, stores `currentPage` and `totalPages` from the response, and sets `state` to `.empty` or `.loaded(movies)`.

**Next page: `loadNextPageIfNeeded(currentItem:)`**
- The view calls it as each row appears.
- It proceeds only if all of these hold:
  - nothing is fetching;
  - `canLoadMore` is true;
  - the first page has loaded (`currentPage > 0`);
  - the item is in `movies`;
  - the item's index is within the last 3 (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- Retrying after a pagination error goes through this same call.

**Refresh: `refresh()`**
- It increments `generation`, clears `isLoadingNextPage` and `paginationError`, and fetches page 1 with `replacing: true`.
- It sets `state = .loading` only if `movies` is empty. With content on screen, the old list stays visible until the new page 1 arrives.
- On success, `fetch` clears `movies` and rebuilds the list from page 1.
- Refresh deliberately has no `isFetching` guard, so it can start while another request is in flight.

**Duplicate and stale requests**
- Duplicate requests:
  - `load()` and `loadNextPageIfNeeded` are guarded by `isFetching`, so rapid scrolling can't fire the same page twice.
  - Results are also de-duplicated by `id` against the `movies` already held. This covers the TMDB case where items shift between pages.
- Stale requests:
  - Each `fetch` captures `generation` as `token`.
  - If a refresh bumped `generation` while the request was in flight, the old response is dropped after the `await`, in both the success and error paths.
  - The `defer` that resets `isFetching` and `isLoadingNextPage` also runs only when the token still matches, so a stale request can't clear the flags of the newer one.
- One caveat: after a refresh starts, `isFetching` stays `true` from the superseded request until the new one finishes. The new request's `defer` clears it.

**Errors**
- `CancellationError` is swallowed silently. The state is unchanged, and `isFetching` is reset if the token matches.
- Stale errors are ignored.
- Any other error is turned into a string with `error.userMessage`:
  - If `movies` is empty (first load, or a refresh that never loaded anything), `state = .failed(message)` and the screen shows a full error.
  - If movies are already loaded, the message goes into `paginationError`. `state` stays `.loaded`, so the list remains visible and the UI can show an inline error or retry.
- A failed `refresh()` over an existing list also lands in `paginationError`, not `.failed`. That is because `movies` hasn't been cleared yet, since the clearing only happens on success.
- After a failed first load, `currentPage` is still 0, so calling `load()` again retries it.