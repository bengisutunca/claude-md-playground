Movie search is added. `swift build` succeeds and `swift test` passes all 45 tests, including the 7 new ones. Nothing is committed.

**What I added**
- **`SearchViewModel`** (`Sources/TMDBApp/ViewModels/SearchViewModel.swift`): `@Observable` and `@MainActor`, with the required `init(service:debounce:sleep:)`, `query`, `state` and `waitForSearch()`. Each change to `query` cancels the previous search task and starts a new one. A search that has been superseded exits before calling the service. Queries under 2 characters after trimming set `state` to `.idle`. An empty result gives `.empty`. Errors give `.failed` with the same messages the movie list uses.
- **`SearchView`** (`Sources/TMDBApp/Views/SearchView.swift`): uses `.searchable` and shows results with `MovieRowView`, plus idle, loading, empty and error messages. The iOS-only modifiers are wrapped in `#if os(iOS)`.
- **Tests** (`Tests/TMDBAppTests/SearchViewModelTests.swift`): they use `MockMovieService`, the fixtures and an injected no-wait `sleep`, so there is no real network or waiting. They cover:
  - a short query not calling the service
  - rapid typing causing a single search
  - the 300 ms delay being passed to `sleep`
  - the `search_inception` result
  - `search_empty` giving `.empty`
  - the error state
  - clearing the query returning to `.idle`

`SearchView` isn't shown anywhere in the app yet, because no existing view hosts `MovieListView` either.