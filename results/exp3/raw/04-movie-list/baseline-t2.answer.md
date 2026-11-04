The popular movies screen is in. `swift build` succeeds and `swift test` passes all 36 tests, including 6 new ones for the view model. I haven't run the screen in an app, so the SwiftUI views are only compile-checked. Nothing is committed, and I didn't touch the fixtures.

**New files**
- `Sources/TMDBApp/ViewModels/ViewState.swift`: the `ViewState<Value>` enum, which is `Equatable` whenever `Value` is.
- `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`: `load()`, `refresh()` and `loadNextPageIfNeeded(currentItem:)`.
- `Sources/TMDBApp/Views/MovieRowView.swift`: poster via `AsyncImage` with a film-icon placeholder, plus title, year and rating.
- `Sources/TMDBApp/Views/MovieListView.swift`: the list with pull to refresh, a loading view, an empty message, and an error message with a "Try Again" button.
- `Tests/TMDBAppTests/MovieListViewModelTests.swift`.

**Behaviours beyond what you specified**
- **Next page:** it loads only when `currentItem` is the last loaded movie. It stops once `totalPages` is reached, and it skips any movie whose id is already in the list.
- **Duplicate calls:** `load()` and `loadNextPageIfNeeded` are ignored while a request is in flight.
- **Refresh:** it requests page 1 and replaces the list. If a `refresh()` interrupts a page that is still loading, that page's result is discarded.
- **Refresh failure:** with content on screen, a failed refresh keeps the list and sets `paginationErrorMessage`, which the list shows as a footnote. With nothing on screen, the screen goes to `.failed`.
- **Next-page failure:** the loaded list stays and the same message is set.
- **Error text:** `APIError` and `URLError` cases map to user-facing strings.

I didn't need any `#if os(iOS)` wrappers, since nothing I used is iOS-only.

**Tests:** first load, pagination across `popular_page1` and `popular_page2` (5 then 7 movies), stopping at the last page, duplicate calls, the error state with recovery, refresh resetting pages, and refresh failure keeping content. All use `MockMovieService`, so nothing touches the network.