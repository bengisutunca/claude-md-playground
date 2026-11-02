Popular movies screen done. `swift build` passes and `swift test` passes all 38 tests, including 8 new ones. I didn't launch the app or look at the UI. Nothing is committed.

**What I added**
- `ViewState<Value>` in `Sources/TMDBApp/ViewModels/ViewState.swift`, equatable when `Value` is.
- `MovieListViewModel` in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`, with the exact API you specified.
- `MovieListView` and `MovieRowView` in `Sources/TMDBApp/Views/`. The row shows the poster via `AsyncImage` (placeholder while loading or if missing), title, year and rating. The list has pull to refresh. There is also a spinner, empty view and error view with a Retry button.
- `Tests/TMDBAppTests/MovieListViewModelTests.swift`, using `MockMovieService`.

I removed the two `.gitkeep` files in `ViewModels/` and `Views/`. I did not touch the fixtures.

**Behavior beyond your spec**
- `loadNextPageIfNeeded` only fires when `currentItem` is the last loaded movie, so scrolling past other rows does nothing.
- If a later page fails, the movies already loaded stay on screen. The message goes to a new `paginationErrorMessage` property, which no view shows yet.
- `refresh()` keeps the current list visible while it reloads. A refresh also discards the result of any page fetch still in flight.
- If the first load fails, `state` becomes `.failed` with a user-facing message.

**Tests**
They cover first load, pagination across `popular_page1` and `popular_page2`, stopping at the last page, ignoring duplicate calls, the error state, recovery after an error, and refresh resetting pages. They also cover non-last items not loading a page, and a page-two failure keeping the loaded movies.

I wrote no `#if os(iOS)` guards because nothing I used is iOS-only.