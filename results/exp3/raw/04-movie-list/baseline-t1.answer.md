The popular movies screen is in. `swift build` succeeds, and `swift test` passes all 35 tests, including the 5 new view model tests. I didn't run the SwiftUI screen, only built it. I didn't commit anything or touch the fixtures.

**What I added**
- **`ViewState<Value>`** (`ViewModels/ViewState.swift`) has the five cases you specified. It is `Equatable` whenever `Value` is.
- **`MovieListViewModel`** (`ViewModels/MovieListViewModel.swift`) has the required API.
  - It stops at `totalPages`, skips duplicate movie IDs, and ignores `load()` and `loadNextPageIfNeeded` calls while a page is loading.
  - Only the last loaded movie triggers the next page.
  - Errors become short user-facing messages, for example "Can't reach the server…" for network failures.
- **`MovieListView` and `MovieRowView`** (`Views/`) show the poster thumbnail, title, year and rating. `AsyncImage` shows a film-icon placeholder until the poster loads. The list supports pull to refresh and has a Retry button on the error screen. There were no iOS-only modifiers, so I didn't need any `#if os(iOS)`.
- **Tests** (`MovieListViewModelTests.swift`) use `MockMovieService`. They cover first load, pagination from `popular_page1` to `popular_page2`, no extra request after the last page, an error on first load, an error on a later page, and refresh resetting back to page 1.

**Behaviour you didn't specify**
- If a later page fails, the movies already loaded stay on screen. The error goes into `paginationErrorMessage` instead of replacing the list with `.failed`.
- `refresh()` keeps the current list visible until page 1 reloads. It also works while a page is still loading, and a response that arrives late is discarded.