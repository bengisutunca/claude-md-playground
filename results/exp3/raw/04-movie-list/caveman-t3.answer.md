The popular movies screen is in. `swift build` succeeds and `swift test` passes all 37 tests, including the 7 new view model tests. I haven't launched the SwiftUI screen, so the list, `AsyncImage` placeholder and pull to refresh are untested. Nothing is committed.

**Files added**
- `ViewModels/ViewState.swift`: the `ViewState<Value>` enum.
- `ViewModels/MovieListViewModel.swift`: the view model with `load()`, `refresh()` and `loadNextPageIfNeeded(currentItem:)`.
- `Views/MovieRowView.swift` and `Views/MovieListView.swift`: the row (poster, title, year, rating) and the list.
- `Tests/TMDBAppTests/MovieListViewModelTests.swift`: the tests, using `MockMovieService`.

I also removed the two `.gitkeep` files in `ViewModels/` and `Views/`.

**How it behaves**
- **Pagination:** pages are appended and it stops at `totalPages`. Only the last loaded movie triggers the next page.
- **Overlapping calls:** a call made while a page is loading is ignored. That includes `refresh()`, so a pull to refresh during a load does nothing.
- **Refresh:** it replaces the list with page 1 and keeps the old list visible until the new page arrives.
- **Errors:** `state` becomes `.failed` only when nothing is loaded yet. If a later page fails, the loaded list stays on screen.
- **Error message:** I added `errorMessage` as an extra property. It holds the last failure's text, which would otherwise be lost when a later page fails.
- **Platform:** I didn't need any `#if os(iOS)` guards, and the package builds on macOS.

The tests cover first load, paging across `popular_page1` and `popular_page2`, end of pages, duplicate calls, the error state, a failed next page and refresh resetting the pages.