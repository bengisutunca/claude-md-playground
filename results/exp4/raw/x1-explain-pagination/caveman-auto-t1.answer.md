`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) runs every request through one private `fetch(page:replacing:)`. It uses two guards: an `isFetching` flag and a `generation` counter. `MovieListView` calls it from three places.

## First load
- `MovieListView` calls `load()` from `.task` when the view appears.
- `load()` does nothing if a request is already running (`isFetching`) or a page has already loaded (`currentPage != 0`). So when the view reappears, nothing is fetched again.
- Otherwise it sets `state = .loading`, which shows `LoadingView`, and fetches page 1.
- If the request succeeds, `fetch` adds the results and stores `currentPage` and `totalPages` from the `PagedResponse`. It then sets `state` to `.loaded(movies)`, or `.empty` if there are no results.

## Next page
- Each row in the `ForEach` has `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }`, so the check runs whenever a row appears on screen.
- It fetches only if all of these are true:
  - no request is running
  - `canLoadMore` (`currentPage < totalPages`)
  - the first page has loaded
  - the row is one of the last 3 loaded movies
- It sets `isLoadingNextPage = true`, which shows a `ProgressView` in the footer, clears `paginationError`, and fetches `currentPage + 1`.
- The new movies are appended. Any whose `id` is already loaded are skipped. TMDB's popular ranking can shift between pages, and repeated ids would also break `ForEach` identity.

## Refresh
- Pull-to-refresh (`.refreshable`), the Retry button in `ErrorView` and the Retry button in the pagination footer all call `refresh()`.
- `refresh()` increases `generation`, resets `isLoadingNextPage` and `paginationError`, and fetches page 1 with `replacing: true`.
- It only switches to `.loading` if nothing is loaded yet. Otherwise the current list stays on screen.
- The old list is cleared only after the new page 1 arrives (`if replacing { movies = [] }`). If the refresh fails, the old list stays.

## Duplicate and stale requests
- **Duplicate requests:** `isFetching` stops `load()` and `loadNextPageIfNeeded` from starting a second request while one is running. For example, several end rows appearing at once start only one page fetch.
- **Stale requests:** `refresh()` deliberately skips the `isFetching` check. It increases `generation` instead. Each `fetch` saves the generation when it starts. When it finishes, it ignores its result or error if the number has changed. The `defer` also leaves `isFetching` and `isLoadingNextPage` alone in that case, because the newer request now owns them.
- The superseded network request is not cancelled. It finishes in the background and its result is thrown away.

## Errors
- Errors are turned into text with `Error.userMessage` (`Networking/APIError.swift`).
- **Nothing loaded yet:** `state = .failed(message)`, and `ErrorView` shows a Retry button that calls `refresh()`.
- **Movies already loaded** (failed next page, or failed refresh): `paginationError` is set, the list stays, and the footer shows the message with a Retry button.
- `CancellationError` is ignored quietly.

## Worth knowing
1. **Cancellation shows up as an error.** `TMDBClient.send` (`Networking/HTTPClient.swift`) wraps every `URLSession` error in `APIError.transport`. A cancelled task's request fails with `URLError(.cancelled)`, so it never reaches `catch is CancellationError`.
   - If a row scrolls off screen during a page fetch, its `.task` is cancelled. The footer then shows "Couldn't reach the server."
   - The same happens if the screen is left during the first load: you get `.failed`. That one recovers, because `currentPage` is still 0 and `load()` runs again on the next appear.
2. **Pagination Retry starts over from page 1.** The footer's Retry calls `refresh()`, not a retry of the failed page. A user who has scrolled through several pages is sent back to one page.
3. **Pagination can stall.** Each row only triggers loading when it appears. If a page adds no new movies (all duplicates), or a page fails and the user doesn't tap Retry, nothing loads until one of the last 3 rows scrolls back into view.
4. **No pull-to-refresh on the empty screen.** `.refreshable` is attached only to the `.loaded` list, so the `.empty` screen can't be refreshed.

I only read the code for this; I didn't build or run anything.