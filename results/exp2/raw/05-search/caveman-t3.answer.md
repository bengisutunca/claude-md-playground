Movie search is in. `swift build` succeeds and `swift test` passes all 45 tests, including the new search tests. I didn't launch the app, so `SearchView` is only compile-checked. Nothing is committed, and nothing under `Fixtures/` was touched.

- **View model:** `Sources/TMDBApp/ViewModels/SearchViewModel.swift` has the required init, `query`, `state` and `waitForSearch()`.
- **Superseded searches:** a new `query` cancels the previous `Task` and bumps a generation counter. A superseded search returns before calling the service, even if the injected `sleep` ignores cancellation.
- **Short queries:** a query under 2 characters after trimming sets `.idle` and never calls the service.
- **States:** a search shows `.loading`, then `.loaded`, or `.empty` when there are no results. Errors become `.failed`, reusing the message mapping in `MovieListViewModel.message(for:)`.
- **View:** `Sources/TMDBApp/Views/SearchView.swift` uses `.searchable` and shows results with `MovieRowView`. It has idle, empty and error messages, plus a spinner while loading. The iOS-only modifiers (`.textInputAutocapitalization`, `.autocorrectionDisabled`) are inside `#if os(iOS)`.
- **Tests:** `Tests/TMDBAppTests/SearchViewModelTests.swift` uses an instant `sleep`, so nothing waits. It covers the cases you listed:
  - a short query does not call the service;
  - rapid typing triggers one search;
  - `search_inception` loads results;
  - `search_empty` gives `.empty`;
  - an error gives `.failed`.

  I also added tests that a short query clears earlier results and that the injected debounce duration reaches `sleep`.

`SearchView` isn't reachable from any screen yet, since the app has no navigation wiring.