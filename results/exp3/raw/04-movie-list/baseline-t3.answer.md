The popular movies screen is in. `swift build` succeeds and `swift test` passes all 37 tests, including the 7 new view model tests. I didn't run the app, so the SwiftUI views are compiled but not exercised. Nothing is committed, and the fixtures are untouched.

**What's there**
- **Files:** `ViewState`, `MovieListViewModel`, `MovieListView` and `MovieRowView` match the names and signatures you gave. They sit under `ViewModels/` and `Views/`, and I deleted the two `.gitkeep` placeholders there.
- **View:** the list shows each poster thumbnail, title, year and rating, with pull to refresh. `AsyncImage` shows a spinner while the poster loads and a film icon if it fails or is missing. No iOS-only modifiers were needed, so there are no `#if os(iOS)` blocks.
- **Tests:** `MovieListViewModelTests.swift` covers first load, pagination across both pages, stopping at the last page, duplicate calls, the error state, and refresh resetting pages. They use `MockMovieService` and the fixtures, so nothing touches the network.

**Behaviours beyond the spec**
- **Next page:** the next page loads only when `currentItem` is the last loaded movie. Pages are de-duplicated by movie id.
- **`load()`:** it only fetches from the idle state. Calling it again after a successful load does nothing; use `refresh()` to reload.
- **`refresh()`:** it resets to page 1 and discards any request still in flight.
- **Errors:** a first-page failure sets `.failed` with a readable message, and the view shows a Retry button. A failure on a later page keeps the loaded list and sets a separate `paginationError`, which the list shows as a footnote.