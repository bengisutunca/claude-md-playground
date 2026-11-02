Popular movies screen added. `swift build` succeeds and `swift test` passes all 38 tests, including the 8 new ones. Nothing is committed. I didn't run the screen in a simulator, so the SwiftUI views are compile-checked only.

**New files**
- `Sources/TMDBApp/ViewModels/ViewState.swift`: `ViewState<Value>` with the five required cases. It is `Equatable` when `Value` is.
- `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`: has the required API plus `errorMessage` and `hasMorePages`.
- `Sources/TMDBApp/Views/MovieRowView.swift`: poster thumbnail via `AsyncImage` with a film-icon placeholder, plus title, year and rating.
- `Sources/TMDBApp/Views/MovieListView.swift`: `List` with pull to refresh and a Retry button on failure. No iOS-only modifiers were needed, so there is no `#if os(iOS)`.
- `Tests/TMDBAppTests/MovieListViewModelTests.swift`: covers first load, pagination across `popular_page1` and `popular_page2`, end of pages, error state, refresh resetting pages, and duplicate calls.

**Behavior**
- `loadNextPageIfNeeded(currentItem:)` fetches only when `currentItem` is the last loaded movie and `totalPages` isn't reached. New pages are appended and duplicate IDs are skipped.
- `load()`, `refresh()` and `loadNextPageIfNeeded` return immediately while a fetch is in flight.
- If a refresh or next-page fetch fails and movies are already shown, the list stays and `errorMessage` is set. An error on the first load puts `state` in `.failed`.
- I wrote the user-facing error text myself, in `MovieListViewModel.message(for:)`. For example, a 401 gives "The TMDB API key was rejected." Change the wording there if you want different text.

I also deleted the two `.gitkeep` files in `ViewModels/` and `Views/`, since those folders now have real files.