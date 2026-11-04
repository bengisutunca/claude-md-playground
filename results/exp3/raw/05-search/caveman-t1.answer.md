Movie search is in. `swift build` succeeds and `swift test` passes all 45 tests (8 suites), including the 7 new search tests. I haven't run the app, so `SearchView` is only compile-checked. Nothing is committed, and the fixtures are untouched.

- **View model:** `SearchViewModel` is in `Sources/TMDBApp/ViewModels/SearchViewModel.swift` and uses the init signature you specified.
  - **Scheduling:** each change to `query` cancels the previous search task and starts a new one.
  - **Superseded searches:** after the injected `sleep` returns, the task checks for cancellation. A superseded search therefore never reaches the service, even if the injected sleep ignores cancellation.
  - **Short queries:** a query under 2 characters after trimming sets `.idle` and skips the service. The service receives the trimmed term.
  - **States:** it shows `.loading` once the debounce has elapsed, and an empty result gives `.empty`.
  - **Errors:** failures reuse `MovieListViewModel.message(for:)`, so error text matches the list screen.
- **View:** `SearchView` is in `Sources/TMDBApp/Views/SearchView.swift`. It uses `.searchable` and shows `MovieRowView` rows, with idle, loading, empty and error messages. The iOS-only modifiers (`.textInputAutocapitalization`, `.autocorrectionDisabled`) are wrapped in `#if os(iOS)`.
- **Tests:** `Tests/TMDBAppTests/SearchViewModelTests.swift` has the tests you listed (short query, rapid typing, `search_inception`, `search_empty`, error state). I also added tests that the debounce value reaches `sleep` and that clearing the query resets to `.idle`. The tests use a no-op `sleep`, so there is no real waiting and no network access.

`SearchView` isn't wired into any parent screen yet, since `MovieListView` has no navigation container. You'll need to place it wherever the app's navigation ends up.