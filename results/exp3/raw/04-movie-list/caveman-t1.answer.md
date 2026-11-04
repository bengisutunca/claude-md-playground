The popular movies screen is in place. `swift build` succeeds and `swift test` passes all 35 tests, including the 5 new ones. Nothing is committed. I only compiled the SwiftUI views and didn't run them, so the screen itself hasn't been seen on screen.

**What I added**
- **`ViewState`** (`ViewModels/ViewState.swift`): the five cases you listed. It is `Equatable` whenever its value is, which the tests use.
- **`MovieListViewModel`** (`ViewModels/MovieListViewModel.swift`): the required API.
  - **Pagination:** it appends pages and stops at `totalPages`. It only fetches the next page when `currentItem` is the last loaded movie, and it drops movies whose id is already in the list.
  - **Duplicate calls:** a call made while a page is loading is ignored.
  - **Error text:** `APIError` maps to user-facing text, and a server-supplied message is used when there is one.
  - **Refresh:** `refresh()` starts over from page 1, and any request still in flight from before it is discarded.
- **`MovieRowView` and `MovieListView`** (`Views/`):
  - **Rows:** poster thumbnail via `AsyncImage` with a placeholder, then title, year and rating.
  - **Screen:** the list has pull-to-refresh and shows loading, empty and error states. The error state has a Retry button, and `.listStyle(.plain)` is wrapped in `#if os(iOS)`.
- **Tests** (`MovieListViewModelTests.swift`, using `MockMovieService`): first load, pagination across `popular_page1` and `popular_page2`, end of pages, duplicate-call guard, error state, and refresh resetting pages.

**Choices to know about**
- **Failed page 2:** if page 2 fails, the loaded list stays on screen and scrolling to the end retries. Only a failed page 1 (from `load()` or `refresh()`) shows `failed`.
- **Failed refresh:** a failed pull-to-refresh replaces the list with the error state. I chose this for simplicity. Say if you'd rather it keep the old list.
- **Visibility:** the new types are internal, like the rest of the package.
- **Cleanup:** I deleted the two `.gitkeep` placeholders in `ViewModels/` and `Views/`.