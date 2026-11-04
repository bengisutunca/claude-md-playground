`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) is a `@MainActor @Observable` class. All three entry points (`load()`, `refresh()`, `loadNextPageIfNeeded(currentItem:)`) go through one private method, `fetch(page:replacing:)`, which calls `MovieService.popular(page:)`. The view is `MovieListView`.

## State it keeps
- **Visible to the view:** `state: ViewState<[Movie]>` (`.idle`, `.loading`, `.loaded`, `.empty`, `.failed`), plus `paginationError` and `isLoadingNextPage`.
- **Internal:** `movies`, `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching` (a flag that blocks a second request while one is running), and `generation` (a counter that marks which request is current).
- `canLoadMore` is `currentPage < totalPages`.

## First load
- `MovieListView` starts it with `.task { await viewModel.load() }`.
- `load()` does nothing if a request is already running or a page has already loaded (`!isFetching, currentPage == 0`). Otherwise it sets `state = .loading` and fetches page 1.
- On success, `fetch` sets `currentPage` and `totalPages` from the `PagedResponse`. State becomes `.loaded(movies)`, or `.empty` if there are no results.
- Because of that guard, `.task` firing again when the view reappears doesn't reload.

## What triggers the next page
- In `MovieListView`, every row in the `ForEach` has `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`, so the trigger is a row appearing on screen.
- `loadNextPageIfNeeded` only fetches if all of these hold:
  - no request is running,
  - `canLoadMore` is true,
  - the first page has loaded,
  - the row is one of the last 3 movies (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true` (the footer shows a `ProgressView`), clears `paginationError`, and fetches `currentPage + 1`.
- New results are added to the end. Any movie whose `id` is already in the list is skipped. TMDB's popular ranking shifts between pages, and duplicate ids would also break the `ForEach`.

## Refresh
- Pull-to-refresh calls `refresh()`, and so do the Retry buttons in `ErrorView` and in the pagination footer.
- It increments `generation`, clears `isLoadingNextPage` and `paginationError`, and fetches page 1 with `replacing: true`.
- It shows `.loading` only if the list is currently empty. Otherwise the old list stays on screen during the request and is replaced only when the new page 1 arrives.
- It doesn't check `isFetching`, so a refresh always starts, even during another request.

## Duplicate and stale requests
- **Same request twice:** `isFetching` blocks overlapping `load()` and next-page calls (the `duplicateCallsWhileLoadingAreIgnored` test covers this). A next-page call during a refresh is also blocked.
- **Stale results:** `fetch` records `generation` when it starts. After the `await`, it drops the result if `generation` has changed since, i.e. a refresh started. A next-page response that arrives after a refresh is therefore thrown away.
- **Who clears the flag:** the `defer` resets `isFetching` and `isLoadingNextPage` only if the request is still current. An old request can't mark a newer one as finished.
- **Duplicate movies:** handled by the `id` check described above.

## Errors
- `error.userMessage` (in `APIError.swift`) turns the error into display text. For example, a 401 becomes "Invalid API key."
- **Nothing loaded yet:** `state = .failed(message)`, and `ErrorView` shows a Retry button that calls `refresh()`.
- **Some movies already loaded:** the list stays and `paginationError` is set. The footer shows the message and a Retry button.
- Errors from an old request are dropped by the same `generation` check.
- `CancellationError` is ignored: no state change, and the `defer` still clears `isFetching`.

## Quirks worth knowing
1. **Cancellation can show up as a network error.** `TMDBClient.send` wraps every `URLSession` error in `APIError.transport`, including the `URLError(.cancelled)` thrown when a SwiftUI `.task` is cancelled. So the `catch is CancellationError` branch probably never runs against the real network. A cancelled request would instead show "Couldn't reach the server." This can happen if the view disappears during the first load, or if the row that triggered a next-page load leaves the screen. After a cancelled first load, `currentPage` is still 0, so the next `.task` runs `load()` again.
2. **The footer's Retry restarts from page 1.** It calls `refresh()`, which throws away all loaded pages, rather than retrying just the failed page. Scrolling to the bottom again does retry the next page, because a newly appearing row triggers `loadNextPageIfNeeded`.
3. **A failed refresh keeps the old list.** Since `movies` isn't cleared until the new page arrives, a refresh that fails shows the error in the footer, not as the full-screen error.
4. **The empty state has no refresh.** `.empty` shows `EmptyStateView`, which isn't inside the `List` that has `.refreshable`, so it can't be pulled to refresh.
5. **Duplicates inside a single response aren't removed.** The check only compares against movies already in the list.

The tests in `Tests/TMDBAppTests/MovieListViewModelTests.swift` cover the first load, pagination stopping at the last page, the last-3 threshold, ignored duplicate loads, the two error paths, and refresh resetting pages. None of them test a refresh arriving during a page load or cancellation. I only read the code; I didn't run the tests or change any files.