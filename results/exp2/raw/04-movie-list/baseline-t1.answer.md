The popular movies screen is in. `swift build` succeeds and `swift test` passes all 36 tests, including the 5 new view model tests. I haven't run the screen in a simulator, so the UI itself is untested. Nothing is committed, and I didn't touch `Fixtures/`.

**What I added**
- **`ViewModels/ViewState.swift`:** `ViewState<Value>` with the five cases you listed.
- **`ViewModels/MovieListViewModel.swift`:** `@MainActor @Observable` with the exact API you specified.
- **`Views/MovieRowView.swift`:** poster thumbnail via `AsyncImage` with a placeholder, plus title, year and rating.
- **`Views/MovieListView.swift`:** `List` with pull to refresh, and separate screens for loading, empty and error. The error screen has a Try Again button, and the iOS-only list style is wrapped in `#if os(iOS)`.
- **`Tests/TMDBAppTests/MovieListViewModelTests.swift`:** tests using `MockMovieService`.

**How the view model behaves**
- **Pagination:** passing the last loaded movie as `currentItem` fetches the next page and appends it, skipping any movie already in the list. It does nothing once `totalPages` is reached, and it ignores any other item.
- **Duplicate calls:** `load()`, `refresh()` and `loadNextPageIfNeeded` all return immediately while a request is already running.
- **Refresh:** it keeps the current list visible until page 1 arrives, then replaces the list and resets pagination.
- **Errors:** a first-page failure sets `.failed` with a plain-language message (for example, "The TMDB API key was rejected." for a 401). A failure on a later page keeps the loaded list and sets `paginationError` instead.

**Tests cover**
- First load.
- Pagination across `popular_page1` and `popular_page2`.
- End of pages.
- Tapping a non-last item doesn't load more.
- Duplicate calls.
- Error state, then recovery on retry.
- Refresh resetting pages.