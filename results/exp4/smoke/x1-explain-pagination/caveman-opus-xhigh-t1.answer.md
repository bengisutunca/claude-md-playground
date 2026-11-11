`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) is a `@MainActor @Observable` class. All three entry points (`load()`, `loadNextPageIfNeeded(currentItem:)`, `refresh()`) go through one private `fetch(page:replacing:)`, which calls `MovieService.popular(page:)`. `MovieListView` calls these methods and draws the screen from the view model's state.

## State it keeps

- **Public, read-only:** `state: ViewState<[Movie]>` (`idle`, `loading`, `loaded`, `empty`, `failed`), `paginationError: String?` and `isLoadingNextPage`.
- **Private:** `movies`, `currentPage` (0 means nothing has loaded yet), `totalPages`, `isFetching` (a request is in flight) and `generation` (a counter that marks which request is current).
- **`canLoadMore`** is simply `currentPage < totalPages`.

## First load

`MovieListView` attaches `.task { await viewModel.load() }` to the whole screen. `load()` (line 28) does nothing if a request is already running or a page has already loaded (`!isFetching, currentPage == 0`). Otherwise it sets `state = .loading` (the view shows `LoadingView`) and fetches page 1.

Because of that guard, the `.task` firing again later doesn't reload. That happens when you come back from a detail screen or switch tabs in `RootView`'s `TabView`.

## What triggers the next page

Each row in the `List` has its own `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`, so the trigger is a row appearing on screen. The method (line 44) only fetches when all of these hold:

- no request is in flight,
- `canLoadMore` is true,
- the first page has loaded,
- the row is one of the **last 3** in `movies`.

If they all hold, it sets `isLoadingNextPage = true` (the footer shows a `ProgressView`), clears `paginationError` and fetches `currentPage + 1`. Pagination ends once `currentPage` reaches the `totalPages` value from the last `PagedResponse`.

## How refresh works

`refresh()` (line 35) is called from three places: `.refreshable` (pull to refresh), the `ErrorView` retry button, and the footer "Retry" button. It:

1. increments `generation`, so any request still running becomes stale;
2. clears `isLoadingNextPage` and `paginationError`;
3. sets `state = .loading` only if nothing is loaded yet, so during a pull-to-refresh the old list stays on screen;
4. fetches page 1 with `replacing: true`.

`movies` is only cleared once the new page 1 **succeeds**, inside `fetch`. If the refresh fails, the old list is kept.

## Duplicate and stale requests

- **Duplicate triggers:** `isFetching` is set at the start of `fetch`. Because everything runs on the main actor, there's no suspension point between the guard check and setting that flag. So when several of the last 3 rows appear at once, or `load()` runs twice, only one request goes out. The `duplicateCallsWhileLoadingAreIgnored` test covers the double `load()` case.
- **Stale responses:** `fetch` records `let token = generation` at the start. When the response or error comes back, it's dropped if `token != generation`, i.e. a refresh started in between. The `defer` block also only resets `isFetching` and `isLoadingNextPage` when the token still matches, so an old request can't clear the flags that belong to the new one.
- **The old request is not cancelled.** It keeps running and its result is ignored.
- `refresh()` deliberately skips the `isFetching` check, so pull-to-refresh always wins over a page load in progress.
- **Duplicate movies:** before appending, results whose `id` is already in `movies` are filtered out (lines 66–67). TMDB's popular list can shift between pages, so this matters. The filter only compares against movies loaded before this response, not against other entries in the same response.
- After merging, `state` becomes `.empty` if there are no movies, otherwise `.loaded(movies)`. `currentPage` and `totalPages` come from the response.

## Errors

- **`CancellationError`:** returns silently. State is unchanged and `isFetching` is reset, so the next trigger can try again.
- **Any other error** (stale ones are dropped first) is turned into text by `Error.userMessage` in `APIError.swift`. For example, 401 becomes "Invalid API key." and `.transport` becomes "Couldn't reach the server…". Then:
  - **nothing loaded yet:** `state = .failed(message)`, and the view shows a full-screen `ErrorView` whose retry calls `refresh()`;
  - **movies already loaded:** `paginationError = message`, the list stays, and the footer shows the message plus a "Retry" button. This covers both a failed next page and a failed pull-to-refresh.

## Gaps I noticed

1. **Cancelled requests show up as network errors.** The `catch is CancellationError` branch doesn't fire for real network calls. `TMDBClient.send` (`HTTPClient.swift`) wraps every `URLSession` error as `APIError.transport`. To my knowledge, `URLSession` reports a cancelled task as `URLError(.cancelled)` rather than `CancellationError`. So when a row's `.task` is cancelled during a page load, the user sees "Couldn't reach the server…" in the footer. That happens if you tap into a detail screen or scroll the row away mid-request. The same happens on a full-screen `.failed` if you switch tabs during the first load. `SearchViewModel` avoids this with `guard !Task.isCancelled` in its general `catch`; `MovieListViewModel` has no such check. I haven't confirmed this at runtime; the tests' mock service only throws errors it's told to.
2. **The footer "Retry" calls `refresh()`.** After a page-N failure, retrying throws away pages 2…N-1 and starts again from page 1, instead of retrying page N.
3. **Pagination can stall.** If every movie in a fetched page is a duplicate, no new rows appear, so no row `.task` fires again. Loading only resumes when one of the last rows scrolls off screen and back.

I didn't change or run anything; this is all from reading the code.