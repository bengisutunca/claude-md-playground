The popular movies screen is in place. `swift build` succeeds and all 35 tests pass, including the 5 new view model tests. I didn't run the screen itself, so the SwiftUI views are compiled but never rendered. Nothing is committed.

**What I added:**
- **`ViewState<Value>`:** the shared enum with the five cases, in `ViewModels/ViewState.swift`. It is `Equatable` when `Value` is.
- **`MovieListViewModel`:** `@MainActor @Observable`, with the exact API you specified. It appends pages and stops at `totalPages`. It ignores `load()` and next-page calls while a request is in flight. `refresh()` resets to page 1 and drops results from any request it superseded.
- **Error handling:** errors are turned into user-facing messages, for example for a missing or rejected API key and for connection problems. If a later page fails, the movies already loaded stay on screen and the message goes into `paginationErrorMessage`.
- **`MovieListView` and `MovieRowView`:** the list shows a poster thumbnail via `AsyncImage` (with a film-icon placeholder), title, year and rating. It supports pull to refresh. It also has loading, empty and error states, and the error state has a Try Again button. The iOS-only `.listStyle(.plain)` is wrapped in `#if os(iOS)`.
- **Tests:** `MovieListViewModelTests.swift` covers first load, pagination across `popular_page1` and `popular_page2`, no extra request after the last page, duplicate calls, the error state with recovery, and refresh resetting the pages. All of them use `MockMovieService` and the existing fixtures, so none touch the network.

I also deleted the two `.gitkeep` files in `ViewModels/` and `Views/`, since those folders now have real files. Nothing under `Fixtures/` was changed.