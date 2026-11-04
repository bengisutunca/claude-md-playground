Movie search is in place. `swift build` succeeds with no warnings and `swift test` passes all 44 tests in 8 suites. Nothing is committed and the fixtures are unchanged.

**Files added**
- `Sources/TMDBApp/ViewModels/SearchViewModel.swift` uses the exact API you specified.
  - Each change to `query` cancels the pending search `Task`. If the trimmed query is under 2 characters, `state` goes to `.idle` and the service isn't called. Otherwise it goes to `.loading` and a new task starts by calling `sleep(debounce)`.
  - After the sleep, and again after the service call, the task checks `Task.isCancelled`. A replaced search therefore never reaches the service and can't overwrite newer results, even if the injected `sleep` ignores cancellation.
  - No results gives `.empty`. Errors give `.failed(...)`, using the error messages from `MovieListViewModel.message(for:)`.
  - `waitForSearch()` waits for the current task to finish.
- `Sources/TMDBApp/Views/SearchView.swift` uses `.searchable` and shows results with `MovieRowView`. It has a prompt for the idle state, a spinner while loading, and `ContentUnavailableView` for the empty and error states. Both `.searchable` and `ContentUnavailableView` work on macOS 14, so no `#if os(iOS)` was needed.
- `Tests/TMDBAppTests/SearchViewModelTests.swift` uses the existing `MockMovieService` and fixtures, with a `sleep` that returns immediately and logs the delay it was given. It tests:
  - a short query doesn't call the service;
  - a short query clears earlier results;
  - rapid typing makes exactly one call, `search("inception", page: 1)`, and the debounce delay is 300 ms;
  - `search_inception` results load;
  - `search_empty` gives `.empty`;
  - a 401 error gives `.failed("Invalid API key.")`.

**Worth knowing**
- `SearchView` isn't added to any app screen yet, because the package has no root navigation. `MovieListView` isn't connected either.
- The error state has no retry button, since you didn't ask for one. Editing the query starts a new search.