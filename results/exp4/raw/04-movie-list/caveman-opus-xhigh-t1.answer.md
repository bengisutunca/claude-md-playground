The popular movies screen is in place. `swift build` is clean and `swift test` passes all 37 tests (7 are new view model tests). Nothing is committed and the fixtures are unchanged.

**What I added**
- **`ViewModels/ViewState.swift`**: the `ViewState<Value>` enum with the five required cases. It's `Equatable` when `Value` is, so tests can compare states directly.
- **`ViewModels/MovieListViewModel.swift`**: has the required API, plus `errorMessage` and `isLoadingNextPage` for the view. How it behaves:
  - Passing the last loaded movie loads the next page and appends it. It stops when `totalPages` is reached. Passing any other movie does nothing.
  - While a page is loading, every other load call is ignored, so pages always arrive in order.
  - `load()` does nothing once a list or an empty result is showing, so the view reappearing doesn't drop the pages already loaded. It retries after a failure.
  - `refresh()` starts over from page 1 and keeps the current list on screen until the response arrives. If the list is removed during a refresh, SwiftUI cancels the refresh.
  - If the first page fails, the state becomes `.failed(message)`. If a later page fails, the list stays and `errorMessage` is set; the view shows it under the list with a "Try Again" button.
  - If a load is cancelled (for example, the view goes away), no error is shown and the next `load()` starts over.
  - A movie that shows up again on a later page is skipped, because a list with repeated IDs misbehaves in SwiftUI.
- **`Networking/APIError.swift`**: `APIError` now provides user-facing messages through `LocalizedError`. For HTTP errors it uses TMDB's own message when there is one. The other view models can reuse this.
- **`Views/MovieListView.swift`** and **`Views/MovieRowView.swift`**:
  - Each row shows the poster through `AsyncImage` (with a placeholder), the title, the year and the rating.
  - The list has pull to refresh and a spinner or retry footer for the next page.
  - Empty and failed states have their own screens.
  - I didn't use any iOS-only modifiers, so no `#if os(iOS)` was needed.

**Tests** (`MovieListViewModelTests.swift`, using `MockMovieService` and the fixtures): first load; pagination across `popular_page1` and `popular_page2`; stopping at the last page; ignoring a second page request while one is loading; the error state using the message from `error_401`, then a successful retry; a failed next page keeping the list; and refresh resetting to page 1. To check that the duplicate-call test really tests something, I removed the guard temporarily: the test failed because page 2 was requested twice, and it passed again with the guard restored.

**Limits**
- The `.empty` state isn't tested, because the mock always returns movies for the popular list and I couldn't change the fixtures.
- The views compile, but I haven't run them in an app or simulator.