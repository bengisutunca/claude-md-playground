`MovieListViewModel` (in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) builds one growing `movies` array from `service.popular(page:)`. It tracks this state:

- **For the view:** `state: ViewState<[Movie]>`, `isLoadingNextPage` and `paginationError`.
- **Internal:** `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching` (blocks a second request while one is running) and `generation` (a counter that makes old results get thrown away).

All three entry points end up in one private function, `fetch(page:replacing:)`.

## First load
`MovieListView` runs `.task { await viewModel.load() }`. `load()` only continues if nothing is running and `currentPage == 0`. It then sets `state = .loading` and fetches page 1.

When the fetch succeeds, it adds the results, saves `currentPage` and `totalPages` from the `PagedResponse`, and sets `state` to `.loaded(movies)`, or `.empty` if there are no movies.

`RootView` keeps the view model in `@State`, so it survives tab switches. Calling `load()` again after a successful load does nothing.

## Next page
Each row in `MovieListView` has `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`. A new page is fetched only if all of these hold:
- nothing is running (`!isFetching`),
- there are more pages (`canLoadMore`, i.e. `currentPage < totalPages`),
- the first page has loaded (`currentPage > 0`),
- the row is one of the last three in the list.

It then sets `isLoadingNextPage = true` (the footer shows a `ProgressView`), clears `paginationError` and fetches `currentPage + 1`. Movies whose IDs are already in the list are skipped, which handles items that move between pages. Duplicates within a single response are not removed.

## Refresh
Pull-to-refresh (`.refreshable`), the Retry button in `ErrorView` and the Retry button in the pagination footer all call `refresh()`. It:
- adds 1 to `generation`,
- clears `isLoadingNextPage` and `paginationError`,
- sets `.loading` only if the list is empty, so existing rows stay on screen while refreshing,
- fetches page 1 with `replacing: true`.

The old list is cleared only when the new page 1 arrives. `refresh()` does not check `isFetching`: it always starts a new request and replaces any running one.

## Duplicate and stale requests
- **Duplicates:** `isFetching` blocks a second `load()` or a second next-page request while one is running. Everything runs on the main actor, and `fetch` sets the flag before its first `await`, so two calls can't both get through. The test `duplicateCallsWhileLoadingAreIgnored` covers this.
- **Stale results:** `fetch` saves the current `generation` before it starts. If the number has changed by the time a response or error comes back, the result is ignored. The cleanup code that resets `isFetching` and `isLoadingNextPage` also only runs if the number still matches, so an old request can't reset the flags of the newer one.

## Errors
Errors are turned into text by `error.userMessage` (in `APIError.swift`), for example "Invalid API key." for a 401.
- **No movies loaded yet:** `state = .failed(message)` and `ErrorView` shows a Retry button that calls `refresh()`. `currentPage` stays at 0, so `load()` also tries again the next time the view appears.
- **Movies already loaded:** this covers a failed next page and a failed refresh. The list stays as it was, `paginationError` is set, and the footer shows the message with a Retry button.
- **`CancellationError`:** the error is ignored without changing `state`.

## Things worth knowing
1. **Footer Retry starts over from page 1.** The Retry button after a failed next page calls `refresh()`, not a next-page retry. Scrolling the last rows off screen and back also retries the next page, without resetting.
2. **Cancelling a request probably shows a fake connection error.** `TMDBClient.send` wraps every `URLSession` error, including `URLError(.cancelled)`, in `APIError.transport`. So the `catch is CancellationError` branch never catches a real network cancellation. SwiftUI cancels a row's `.task` when the row leaves the screen. If that happens while the next page is loading, the footer would probably say "Couldn't reach the server. Check your connection." Switching tabs during the first load would set `.failed` in the same way, though `load()` retries when you come back. I worked this out from the code and haven't run it.
3. **The empty state can't be left.** `EmptyStateView` has no retry and no `.refreshable`. Since `currentPage` is already 1, `load()` won't run again either.

I only read the code; I didn't change any files or run the tests. The behaviour above matches what `MovieListViewModelTests` checks: first load, paging to the end, ignoring duplicate calls, the error state, retrying, keeping the list after a page fails, and refresh resetting the pages.