`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) keeps the screen's state in `state: ViewState<[Movie]>` and puts footer state in `isLoadingNextPage` and `paginationError`. Behind those it tracks the accumulated `movies`, `currentPage`, `totalPages`, an `isFetching` flag and a `generation` counter. All three entry points (`load()`, `loadNextPageIfNeeded(currentItem:)`, `refresh()`) go through one private method, `fetch(page:replacing:)`, which calls `MovieService.popular(page:)`. The class is `@MainActor`, so every state change happens on the main actor, between `await`s.

## First load
`MovieListView` calls `load()` from `.task` on the screen.
- The guard `!isFetching, currentPage == 0` makes it run only when nothing has loaded yet and no request is running. If the view reappears after a successful load, nothing happens. If the first load failed, `currentPage` is still 0, so reappearing tries again.
- It sets `state = .loading`, which shows `LoadingView`, then fetches page 1.
- On success, `currentPage` and `totalPages` are set from the `PagedResponse`, and `state` becomes `.loaded(movies)`, or `.empty` if no movies came back.

## What triggers the next page
Each row has `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`. It runs when the row appears, and it only fetches if all of these hold:
- no fetch is running (`!isFetching`)
- `canLoadMore` (`currentPage < totalPages`)
- the first page has loaded (`currentPage > 0`)
- the row is one of the last 3 in `movies` (`index >= movies.count - 3`)

When those hold, it sets `isLoadingNextPage = true`, which shows a `ProgressView` in the footer. It also clears `paginationError` and fetches `currentPage + 1`. New results are appended, and any movie whose `id` is already in the list is skipped, because TMDB's popular rankings can shift between pages.

## Refresh
Pull-to-refresh (`.refreshable`), the `ErrorView` Retry button and the footer Retry button all call `refresh()`:
- It increments `generation` and clears `isLoadingNextPage` and `paginationError`.
- It shows `.loading` only if no movies are on screen. Otherwise the old list stays visible while the refresh runs.
- It fetches page 1 with `replacing: true`. `movies` is emptied only after the response arrives, so a failed refresh doesn't wipe the list.
- It deliberately skips the `isFetching` check, so a refresh always starts, even if another request is running.

## Duplicate and stale requests
- **Duplicates:** `isFetching` stops `load()` and next-page requests from starting while another request is running. Many rows can fire `.task` near the end of the list, but only one page request goes out.
- **Stale results:** `fetch` records `generation` in `token` before the network call. When the call returns, the success path and the error path both drop the result if `token != generation`, meaning a refresh has started since. This covers an old page request finishing after a refresh, and an earlier refresh finishing after a later one.
- **Flag cleanup:** the `defer` resets `isFetching` and `isLoadingNextPage` only if the request is still current. A superseded request can't clear the flags while the newer request is still running.

## Errors
- `CancellationError` is ignored: no state change and no message.
- For any other error, stale results are dropped first. Then the message comes from `Error.userMessage` (`Networking/APIError.swift`):
  - With no movies loaded, `state = .failed(message)` and the full-screen `ErrorView` appears, whose Retry calls `refresh()`.
  - With movies already loaded, `paginationError = message`. The list stays and the footer shows the message with a Retry button. A failed refresh over an existing list ends up here too, with the old list and page counters unchanged.

## Things to be aware of
1. **The footer Retry restarts from page 1.** It calls `refresh()`, not a retry of the failed page, so it throws away the pages already loaded. Scrolling a last-3 row back into view also retries, by calling `loadNextPageIfNeeded` again.
2. **Network cancellations show up as errors.** `TMDBClient.send` (`Networking/HTTPClient.swift`) wraps every `URLSession` error in `APIError.transport`, including the `URLError(.cancelled)` that URLSession throws when a task is cancelled. As a result, `catch is CancellationError` never catches a real network cancellation. SwiftUI cancels `.task` when a view disappears. So if a row scrolls off screen during a next-page fetch, the footer shows "Couldn't reach the server". If the user leaves the screen during the first load, it shows the full-screen error.
3. **Pagination can stall.** If a page contains only movies already in the list, `currentPage` advances but no rows are added. No new row then appears to trigger the next fetch, so loading stops until a last-3 row scrolls back into view.