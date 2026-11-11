The popular movies screen is in place. `swift build` and `swift test` both pass: 42 tests, 12 of them new view model tests, with no build warnings. Nothing is committed.

**New files**
- `Sources/TMDBApp/ViewModels/ViewState.swift`: the `ViewState<Value>` enum with the five cases you listed. It is comparable when the value type is, which lets tests check `state == .loaded(...)`. There is also a small helper that turns any error into a message for the user.
- `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`: the view model with the API you specified. Beyond that:
  - Pages are added to the list, and loading stops at `totalPages`.
  - A request for the next page is ignored while a page is already loading, and so is a `currentItem` that isn't the last loaded movie.
  - `load()` does nothing once movies are loaded, so it is safe to call each time the screen appears. After a failure it works as a retry.
  - `refresh()` starts again from page 1 and drops the result of any page request still in flight. The current list stays on screen until the new page 1 arrives.
  - Movies already in the list are skipped when the next page arrives, so the list never shows the same movie twice.
  - If the first page fails, `state` becomes `.failed(message)`. If a later page or a refresh fails while movies are shown, the list stays and the error goes into a separate `errorMessage`.
- `Sources/TMDBApp/Views/MovieRowView.swift`: poster thumbnail via `AsyncImage` with a film-icon placeholder, plus title, year and rating. VoiceOver reads each row as one item.
- `Sources/TMDBApp/Views/MovieListView.swift`: shows a spinner, the list, an empty message or an error with "Try Again". Pull to refresh works, and the bottom of the list shows a spinner while the next page loads, or the error with a retry button.
- `Tests/TMDBAppTests/MovieListViewModelTests.swift`: covers first load, pagination across `popular_page1` and `popular_page2`, end of pages, duplicate calls while a page loads, first-load error, retry, an error on page 2 keeping the list, refresh resetting pages, and the generic message for unknown errors. Everything goes through `MockMovieService`, so no test touches the network.

**Changed file:** `Sources/TMDBApp/Networking/APIError.swift` now gives each API error a readable message. For HTTP errors it uses TMDB's own `status_message` when the response has one. Later view models can reuse these messages.

**Two things to know:**
- `MovieListView` sets the "Popular" title but needs to be placed inside a `NavigationStack` for it to show. I left that to the app shell task.
- None of the modifiers I used are iOS-only, so no `#if os(iOS)` was needed.