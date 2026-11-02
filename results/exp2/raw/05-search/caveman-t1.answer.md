Search added. `swift build` succeeds and `swift test` passes (45 tests, including 7 new ones).

**New files**
- `Sources/TMDBApp/ViewModels/SearchViewModel.swift`
- `Sources/TMDBApp/Views/SearchView.swift`
- `Tests/TMDBAppTests/SearchViewModelTests.swift`

**View model**
- Setting `query` cancels the previous search task and schedules a new one.
- The task calls `sleep(debounce)` and then checks for cancellation. A superseded search returns before it calls the service.
- A query under 2 characters after trimming cancels any pending search and sets `.idle`.
- A search with no results sets `.empty`. A failure sets `.failed`, using the same error text as `MovieListViewModel.message(for:)`.
- `waitForSearch()` awaits the current task.

**View**
- `SearchView` uses `.searchable` and shows results with `MovieRowView`. It has idle, loading, empty and error states.
- The iOS-only modifiers are wrapped in `#if os(iOS)`.
- Nothing in the app creates `SearchView` yet, so it isn't reachable from the UI.

**Tests**
- A short query does not call the service.
- Rapid typing triggers one search.
- A superseded search does not call the service.
- A query clearing earlier results back to `.idle`.
- `search_inception` loads results.
- `search_empty` gives `.empty`.
- A 401 error gives `.failed("Invalid API key.")`.
- The tests use a recording `sleep` stub, so none of them waits in real time.

I didn't commit, and I left the fixtures alone.