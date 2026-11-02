The popular movies screen is in. `swift build` succeeds and `swift test` passes all 34 tests, including the 4 new view model tests. I didn't run the screen in a simulator or on a device. I haven't committed anything, and I didn't touch the fixtures.

**Added:**
- **`ViewState`:** `Sources/TMDBApp/ViewModels/ViewState.swift`. It is `Equatable` whenever its value is, so tests can compare states directly.
- **`MovieListViewModel`:** `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`, with `load()`, `refresh()` and `loadNextPageIfNeeded(currentItem:)`.
  - **Pagination:** it appends pages and stops at `totalPages`. It only loads the next page when `currentItem` is the last loaded movie, and it ignores calls made while a page is already loading.
  - **Refresh:** `refresh()` resets to page 1. Any request still in flight from before the refresh has its result dropped.
  - **Errors:** a failure on the first page sets `.failed` with a user-facing message (for example, a 401 gives "Authentication failed. Check your TMDB API key."). A failure on a later page keeps the movies already shown and sets `paginationErrorMessage` instead.
- **Views:** `MovieListView` and `MovieRowView` are in `Sources/TMDBApp/Views/`.
  - **List:** a pull-to-refresh `List` that loads the next page as rows appear. It also has a retry button on the failed state and a spinner while loading.
  - **Row:** poster thumbnail via `AsyncImage` with a placeholder, plus title, year and rating.
  - **Platform:** `.listStyle(.plain)` is wrapped in `#if os(iOS)`.
- **Tests:** `Tests/TMDBAppTests/MovieListViewModelTests.swift` uses `MockMovieService` and the fixtures. It covers first load, pagination across `popular_page1` and `popular_page2`, end of pages, the error state, and refresh resetting pages.

I haven't wired `MovieListView` into an app entry point, since the package has none.