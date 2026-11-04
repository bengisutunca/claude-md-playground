The popular movies screen is in, and `swift build` and `swift test` both pass (35 tests, including 5 new view model tests). I haven't run the SwiftUI views on a device or simulator, only built them on macOS.

**What was added**
- **`ViewState`** (`ViewModels/ViewState.swift`): the five-case enum. It is `Equatable` when its value type is.
- **`MovieListViewModel`** (`ViewModels/MovieListViewModel.swift`):
  - `load()` only fetches from `idle`.
  - `loadNextPageIfNeeded(currentItem:)` fetches the next page only when the item is the last loaded movie and `totalPages` hasn't been reached.
  - `refresh()` fetches page 1 again and replaces the list.
  - Errors map to user-facing messages.
- **`MovieRowView` and `MovieListView`** (`Views/`):
  - The row shows a poster via `AsyncImage` with a film-icon placeholder, plus title, year and rating.
  - The list has pull-to-refresh and a Retry button on the error screen.
  - `.listStyle(.plain)` is wrapped in `#if os(iOS)`.
- **Tests** (`Tests/TMDBAppTests/MovieListViewModelTests.swift`): first load, pagination across `popular_page1` and `popular_page2`, stopping at the last page, duplicate `load()` calls, the error state, and refresh resetting pages. They use `MockMovieService`, so nothing touches the network.

**Behaviors you might not expect**
- If a page after the first fails, the list stays on screen with no error shown. The next scroll to the last row retries it.
- If a refresh fails, the list is cleared and the error state is shown.
- A page fetch still running when `refresh()` is called is discarded, so stale results can't be appended after the reset.

I deleted the two `.gitkeep` files in `ViewModels/` and `Views/` since those folders now have real files. Nothing is committed, and the fixtures are untouched.