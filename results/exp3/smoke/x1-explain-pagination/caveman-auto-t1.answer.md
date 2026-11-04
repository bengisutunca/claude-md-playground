`MovieListViewModel` (in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`) does all three kinds of load (first load, next page, refresh) through one private `fetch(page:replacing:)` method. `MovieListView` decides when each one is called.

## State it keeps
- **Visible to the view:** `state: ViewState<[Movie]>` (`idle`, `loading`, `loaded`, `empty` or `failed`), plus `isLoadingNextPage` and `paginationError` for the list footer.
- **Internal:** `movies`, `currentPage` (starts at 0, meaning nothing loaded yet), `totalPages` (starts at 1), `isFetching`, and `generation`, a counter that marks which request is current.
- `canLoadMore` is simply `currentPage < totalPages`.

## First load
- `MovieListView` calls `.task { await viewModel.load() }`.
- `load()` exits early if a request is already running or if a page has already loaded (`currentPage != 0`). Re-running the `.task`, for example when the view reappears, therefore does nothing once data is there.
- Otherwise it sets `state = .loading` (the view shows `LoadingView`) and fetches page 1.
- On success, `fetch` adds the results to `movies` and stores `currentPage`/`totalPages` from the `PagedResponse`. It then sets `.loaded(movies)`, or `.empty` if there are no results.

## What triggers the next page
- Each row in the `List` has its own `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`, so the trigger is a row appearing on screen.
- The next page loads only if all of these hold:
  - no request is running (`!isFetching`)
  - `canLoadMore`
  - the first page has loaded (`currentPage > 0`)
  - the row is one of the **last 3** in `movies`
- If they hold, it sets `isLoadingNextPage = true` (the footer shows a spinner), clears `paginationError`, and fetches `currentPage + 1`.
- New results are filtered against the IDs already loaded and appended, so a movie that moves between pages on TMDB doesn't appear twice. `currentPage` is set from `response.page`.

## Refresh
- Three places call `refresh()`: pull-to-refresh (`.refreshable`), the Retry button on the full-screen `ErrorView`, and the Retry button in the pagination-error footer.
- `refresh()`:
  1. Increments `generation`, which marks any running request as out of date.
  2. Clears `isLoadingNextPage` and `paginationError`.
  3. Sets `state = .loading` only if no movies are loaded. Otherwise the existing list stays on screen during the refresh.
  4. Calls `fetch(page: 1, replacing: true)`.
- The current list is cleared only when the new page 1 arrives (`if replacing { movies = [] }`). A failed refresh therefore never wipes a list that's already showing.
- Unlike the other two paths, `refresh()` doesn't check `isFetching`. It always starts a new request and relies on `generation` to discard the older one.

## Duplicate and out-of-date requests
- **Duplicate requests:** `isFetching` blocks `load()` and `loadNextPageIfNeeded` while any fetch is running. Several rows appearing at once start only one page request.
- **Out-of-date results:** `fetch` records `generation` when it starts. After the request returns, results are applied and errors reported only if `generation` hasn't changed since. A page request that finishes after a refresh started is discarded, and so is an older refresh that loses to a newer one.
- **Cleanup:** the `defer` block resets `isFetching` and `isLoadingNextPage` only for the current request, so a superseded request can't clear the flags of the one that replaced it.
- **Duplicate movies:** handled by the ID filter described above.

## Errors
- Error text comes from `Error.userMessage` in `Networking/APIError.swift`. It produces messages for a missing API key, a 401, other HTTP statuses, transport failures and decoding failures.
- **Nothing loaded yet:** `state = .failed(message)`. The view shows `ErrorView`, and its Retry calls `refresh()`.
- **Movies already loaded:** only `paginationError` is set. The list stays, and the footer shows the message with a Retry button.
- **Errors from out-of-date requests** are ignored.
- **`CancellationError`** is ignored and changes no state. If the first load is cancelled, `currentPage` is still 0, so the next `load()` tries again.

## Things worth knowing
1. **Footer Retry restarts from page 1.** In the pagination footer, Retry calls `refresh()`. It throws away all loaded pages and fetches page 1, instead of retrying the page that failed.
2. **Real cancellations don't reach the cancellation handler.** `HTTPClient.send` wraps every `URLSession` error, including `URLError.cancelled`, in `APIError.transport`. So when SwiftUI cancels a `.task`, for example when the row that started a page fetch scrolls away or the view disappears during the first load, `catch is CancellationError` doesn't match. The user sees "Couldn't reach the server…" as either `paginationError` or `.failed`. Only a cancellation thrown directly as `CancellationError` (such as a check before the request starts) is ignored quietly.
3. **No automatic retry.** After a page error, `currentPage` doesn't advance. The next attempt happens only when a row in the last three appears again, or the user taps Retry.

The tests that cover this view model are in `Tests/TMDBAppTests/MovieListViewModelTests.swift`, using `MockMovieService`. I only read the code; I didn't run anything.