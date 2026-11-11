`MovieListViewModel` (`Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) loads pages from `MovieService.popular(page:)`. It tracks the current page and total pages, and uses two guards: an `isFetching` flag that blocks overlapping requests, and a `generation` counter that drops responses a refresh has made out of date. All UI triggers live in `MovieListView`.

## State it keeps

- **Public:** `state: ViewState<[Movie]>` (`idle` / `loading` / `loaded` / `empty` / `failed`), `paginationError: String?` and `isLoadingNextPage`.
- **Private:** `movies`, `currentPage` (starts at 0, meaning nothing loaded yet), `totalPages`, `isFetching` and `generation`.
- **`canLoadMore`:** `currentPage < totalPages`.
- The class is `@MainActor`, so every check and every state change runs on one thread.

## First load

- `MovieListView` calls `.task { await viewModel.load() }`. `RootView` owns the view model in `@State`, so it survives tab switches.
- `load()` (line 28) only runs if nothing is in flight (`!isFetching`) and nothing has loaded yet (`currentPage == 0`). It sets `state = .loading`, which shows `LoadingView`, then calls `fetch(page: 1)`.
- `.task` runs again whenever the view reappears. After a successful load that's a no-op because `currentPage` is 1. After a failed first load `currentPage` is still 0, so coming back to the tab retries.

## What triggers the next page

- Each row in the `List` has `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`, so the trigger is a row appearing on screen.
- `loadNextPageIfNeeded` (line 44) only fetches if all of these hold:
  - nothing is in flight;
  - `canLoadMore`;
  - the first page has loaded (`currentPage > 0`);
  - the row is one of the last 3 (`index >= movies.count - 3`).
- It then sets `isLoadingNextPage = true` (the footer shows a `ProgressView`), clears `paginationError`, and fetches `currentPage + 1`.
- When the page arrives, `fetch` adds only movies whose `id` isn't already in the list. TMDB's popular ranking shifts between requests, so the same movie can show up on two pages. `ForEach` needs unique ids, so this filter matters.
- `currentPage` and `totalPages` come from the response. Once the last page is reached, `canLoadMore` is false and the trigger stops (tested in `paginationAppendsPage2AndStopsAtEnd`).

## How refresh works

`refresh()` (line 35) is called from three places in `MovieListView`:
- pull-to-refresh (`.refreshable`);
- the Retry button on the full-screen `ErrorView`;
- the Retry button in the list footer after a pagination error.

It does four things:
1. `generation += 1`, which marks any request already in flight as outdated.
2. Resets `isLoadingNextPage` and `paginationError`.
3. Sets `state = .loading` only if the list is empty. With movies on screen, the list stays visible during a pull-to-refresh and gets swapped when page 1 arrives.
4. Calls `fetch(page: 1, replacing: true)`. Unlike `load()`, it skips the `isFetching` check on purpose, because it's meant to replace whatever is running.

`movies` is cleared only after page 1 succeeds, and `currentPage` resets at the same moment. If the refresh fails, the old list stays (`refreshResetsPages` covers the success case).

## Duplicate and outdated requests

- **Duplicate calls:** `isFetching` is set inside `fetch` before the first `await`. Because everything runs on the main actor, two overlapping `load()` calls, or several of the last 3 rows appearing at once, can't both get through (`duplicateCallsWhileLoadingAreIgnored`).
- **Outdated responses:** `fetch` saves `generation` before the network call and compares it afterwards. If a refresh happened in between, the result is thrown away, whether it succeeded or failed. Without this, a late page 3 could be added to a freshly refreshed page 1 and set `currentPage` to 3.
- The `defer` only resets `isFetching` and `isLoadingNextPage` if the request is still current. An outdated request therefore can't clear the flags of the refresh that replaced it.
- **Duplicate movies:** handled by the id filter described above.

## Errors

- `error.userMessage` (in `APIError.swift`) turns an error into a user-facing message, for example 401 becomes "Invalid API key." and a connection failure becomes "Couldn't reach the server…".
- **No movies loaded yet:** `state = .failed(message)`, which shows the full-screen `ErrorView` with Retry.
- **Movies already loaded:** `paginationError = message`. The list stays and the footer shows the message with Retry (`paginationErrorKeepsLoadedMovies`). `currentPage` doesn't change, so scrolling the last rows off and back on screen tries the same page again.
- **`CancellationError`:** ignored. State is left alone and the `defer` still clears the flags.

## Things worth knowing (from reading the code; no tests cover them)

1. **Real cancellations don't reach the `CancellationError` check.** `TMDBClient.send` in `HTTPClient.swift` wraps every `URLSession` error as `APIError.transport`, including `URLError(.cancelled)`. The pagination request runs inside a row's `.task`, which SwiftUI cancels when the row leaves the screen. Scrolling that row away mid-request would show "Couldn't reach the server" in the footer. The same applies to switching tabs during the first load, though the `.task` retry on return usually hides it.
2. **The footer's Retry does a full refresh, not a retry of the failed page.** After a pagination error, all loaded pages are replaced by page 1.
3. **A failed pull-to-refresh only shows its error in the footer**, at the bottom of the list, while the user is at the top.
4. **The id filter only checks against movies already in the list**, not within the new page. A page that repeats an id would still add both.