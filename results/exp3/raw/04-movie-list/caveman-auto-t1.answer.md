The popular movies screen is in place. `swift build` succeeds on macOS and `swift test` passes all 41 tests, including 11 new view model tests. Nothing is committed and the fixtures are unchanged.

**What I added**
- **`ViewState.swift`:** the `ViewState<Value>` enum with the five cases you listed. It is also Equatable and Sendable when its value is.
- **`MovieListViewModel.swift`:** has the exact API you specified. It also exposes `errorMessage`, `isLoadingPage` and `hasMorePages`.
  - Passing the last loaded movie loads the next page and adds it to the list. It stops once `totalPages` is reached, and calls made while a page is loading are ignored.
  - `load()` does nothing if movies are already loaded, so running it every time the screen appears is safe. It also works as a retry after an error.
  - `refresh()` starts again from page 1, and the current movies stay on screen until the new page arrives. If an older page request finishes after a refresh, its result is thrown away.
  - If the first page fails, the screen shows `.failed(message)`. If a later page or a refresh fails, the movies stay on screen and `errorMessage` is set.
  - Movies repeated across pages are dropped, so each movie appears once in the list.
- **`APIError.swift`:** the user-facing error text lives here, on `APIError` itself, so future screens can reuse it. There are specific messages for a missing key, an invalid key, not found, server errors and no connection. Anything else gets "Something went wrong. Please try again."
- **`MovieListView.swift`:** shows a spinner while loading, then the list. Pull to refresh works on both the list and the empty screen. The empty and failed states have their own screens, and the failed one has a "Try Again" button. The bottom of the list shows a spinner while the next page loads, or the error message with a "Load More" button if a page fails.
- **`MovieRowView.swift`:** poster thumbnail via `AsyncImage` with a film-icon placeholder, plus title, year and rating, read as one item by VoiceOver.
  - No iOS-only modifiers were needed, so there is no `#if os(iOS)` code.
- **`MovieListViewModelTests.swift`:** uses `MockMovieService` and the fixtures, with no network calls. It covers the five cases you asked for, plus:
  - `load()` not reloading once movies are loaded
  - a movie other than the last one not triggering a page load
  - duplicate calls made at the same time
  - a next-page error keeping the movies on screen
  - retrying after an error

I also deleted the `.gitkeep` placeholder files in `ViewModels/` and `Views/`, since both folders now have real files.

One thing you may want to change: during a pull to refresh, the spinner at the bottom of the list shows alongside the refresh indicator.