Movie search is in. `swift build` succeeds with no warnings, and `swift test` passes all 44 tests in 8 suites. Nothing is committed and the fixtures are untouched.

**What I added**
- **`ViewModels/SearchViewModel.swift`**: uses the exact API you specified.
  - Changing `query` cancels the previous search and trims the new text. If it's under 2 characters, `state` goes to `.idle` without calling the service. Otherwise `state` goes to `.loading` and a new search starts.
  - The search first calls `sleep(debounce)`. After that it checks whether it was cancelled before calling the service, because a test's fake sleep may not throw when cancelled. It checks again before writing `state`, so a superseded search never calls the service or overwrites newer results.
  - It searches with the trimmed text, page 1 only. An empty result gives `.empty`, an error gives `.failed(message)`, and a cancellation is ignored.
  - `waitForSearch()` waits for the current search task to finish.
- **`Views/SearchView.swift`**: uses `.searchable` and shows results with `MovieRowView`. It has screens for idle (a prompt to type at least 2 characters), loading, empty and error. Only the iOS search placement (`.navigationBarDrawer`) is inside `#if os(iOS)`; macOS uses plain `.searchable`.
- **`Tests/TMDBAppTests/SearchViewModelTests.swift`**: the tests use `MockMovieService` and a fake sleep that only records the requested delay, so nothing waits or touches the network. They cover the five cases you asked for:
  - a short query doesn't call the service (or sleep)
  - five quick keystrokes produce one service call, with a 300 ms delay requested
  - `search_inception` loads Inception (id 27205)
  - `search_empty` gives `.empty`
  - a 401 gives `.failed("Invalid API key.")`
  
  There's one extra test: a short query after a successful search clears the results back to `.idle`.

**One change to existing code:** I moved the error-to-message mapping out of `MovieListViewModel` into a new shared `ViewModels/ErrorMessage.swift`, so both view models show the same error text. The mapping itself is unchanged. `MovieListViewModel.message(for:)` no longer exists, but nothing else used it.

**Not done:** the error screen has no retry button; you retry by editing the query. Search loads only the first page of results. Nothing in the app opens `SearchView` yet, because the package has no root view to add it to.