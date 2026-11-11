The popular movies screen is in place. `swift build` gives no errors or warnings, and `swift test` passes all 37 tests, including 7 new view model tests. I haven't run the app itself, so the views are only checked by the compiler. Nothing is committed, and the fixture files are untouched.

**What I added**
- **`ViewModels/ViewState.swift`**: the shared `ViewState<Value>` enum with the five cases. Two extras: it supports `==` when the value does, and `.value` returns the loaded content.
- **`ViewModels/UserFacingError.swift`**: turns each API error into a plain-language message, e.g. a bad API key gives "TMDB rejected the API key…". Later screens can reuse it.
- **`ViewModels/MovieListViewModel.swift`**: the required API, plus `errorMessage`, `isLoadingNextPage`, `hasMorePages` and `retry()`.
- **`Views/`**:
  - `MovieListView`: spinner, list, empty and error screens, a footer for the next-page spinner or error, and pull to refresh.
  - `MovieRowView`: poster, title, year and rating.
  - `PosterImage`: an `AsyncImage` that shows a placeholder while loading, on failure, or when there's no poster.

  None of these use iOS-only modifiers, so no `#if os(iOS)` was needed.

**Behaviour you might not assume**
- **`load()` runs only once.** After movies have loaded (or the list came back empty) it does nothing, so returning to the screen doesn't reload it or jump back to the top. "Try Again" after a failure still loads.
- **Errors don't wipe the list.** If the first load fails with nothing on screen, the state becomes `.failed(message)`. If a later page or a refresh fails, the list stays and the footer shows the message with a "Try Again" button that calls `retry()`.
- **Refresh keeps the current list on screen** until page 1 comes back. Any page still loading when you refresh is thrown away when it arrives, so old results can't be added to the new list.
- **A cancelled load isn't an error.** If the user leaves the screen mid-load, no error is shown and the next visit loads again.
- **Duplicates are dropped and paging stops at page 500.** TMDB can repeat a movie on neighbouring pages, which breaks SwiftUI lists, and it rejects page numbers above 500 whatever `total_pages` says.

**Tests**
- They cover your five cases, plus two more: duplicate calls while a page is loading are ignored, and a failed next page keeps the list and can be retried.
- To test the duplicate-call guard properly, I added an optional hook to `MockMovieService` (`holdNextResponse()` / `releaseHeldResponse()`). It pauses one response until the test releases it, and existing uses of the mock are unchanged.
- I checked that this test catches a missing guard by removing the guard for a moment. My first version of the hook made the test hang instead of fail, so I changed it to pause only one call. With the guard removed, the test now fails right away; with it back, the suite passes.