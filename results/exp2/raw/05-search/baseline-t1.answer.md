Movie search is in. `swift build` succeeds and `swift test` passes all 45 tests, including the 7 new ones. I haven't run the UI, so `SearchView` is only verified to compile on macOS.

**What's there**
- **`SearchViewModel`** (`Sources/TMDBApp/ViewModels/SearchViewModel.swift`): it has the exact init signature and `waitForSearch()` you specified. Setting `query` cancels the previous `Task` and starts a new one that first calls `sleep(debounce)`. If the task was cancelled while sleeping, it never calls the service. Queries under 2 characters after trimming set `.idle`. An empty result is `.empty`. Errors are mapped to `.failed` using the existing `MovieListViewModel.message(for:)`.
- **`SearchView`** (`Sources/TMDBApp/Views/SearchView.swift`): it uses `.searchable`, shows results with `MovieRowView`, and has idle, loading, empty and error states. I didn't need any `#if os(iOS)` wrapping, because the modifiers it uses build on macOS.
- **Tests** (`Tests/TMDBAppTests/SearchViewModelTests.swift`): they inject an instant `sleep`, so nothing waits in real time, and they use `MockMovieService`, so there's no network. They cover:
  - a short query makes no service call;
  - a short query after a result clears it to `.idle`;
  - rapid typing triggers one search;
  - the `search_inception` result;
  - the `search_empty` result gives `.empty`;
  - the error state;
  - the 300 ms debounce value is passed to `sleep`.

**Not wired up**
- Nothing links `SearchView` into the app. `TMDBApp.swift` and `MovieListView` are unchanged, so there's no tab or navigation entry for search yet.

I made no commits and didn't touch the fixtures.