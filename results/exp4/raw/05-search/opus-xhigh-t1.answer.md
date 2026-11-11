Movie search is in place. `swift build` gives no warnings and `swift test` passes all 47 tests: the 38 existing ones plus 9 new search tests. Nothing is committed, and the fixtures are unchanged.

**New files**
- `Sources/TMDBApp/ViewModels/SearchViewModel.swift`: uses the exact API you specified. Each change to `query` cancels the previous search task and starts a new one, which calls `sleep(debounce)` first. Queries under 2 characters after trimming set `.idle` right away, with no task and no service call. A search that's been replaced never calls the service and never updates `state`, even if `sleep` returns normally instead of throwing.
- `Sources/TMDBApp/Views/SearchView.swift`: `.searchable` with results in a `List` of `MovieRowView`. Empty results use `ContentUnavailableView.search`, and errors show the message with a "Try Again" button. The iOS-only `.navigationBarDrawer` search placement is inside `#if os(iOS)`.
- `Tests/TMDBAppTests/SearchViewModelTests.swift`: the five tests you listed, plus tests for short queries clearing old results, the default 300 ms debounce being used, input trimming, and retry. They use `MockMovieService` with the fixtures and a fake `sleep`, so there's no real waiting and no network.

**Choices you may want to change**
- **Loading state:** `.loading` is set after the debounce, just before the request. While the user is typing, the previous results stay on screen.
- **Extra method:** I added `retry()` for the "Try Again" button. It re-runs the current query immediately, skipping the debounce.
- **Error messages:** I reused `MovieListViewModel.message(for:)` so both screens show the same wording. If you'd rather not have that dependency, it could move to a shared helper.
- **Not wired in yet:** `SearchView` isn't connected to anything, because there's no app shell yet.

**Checks**
- **Rapid typing:** the basic "rapid typing" test can pass by luck when the code is broken, because the replaced searches might run after its checks. So I added `supersededSearchDoesNotCallService`. It holds the old search's `sleep`, sends a new query, lets the old one finish and only then checks the service, so the order is fixed.
- **Tests catch the bug:** I temporarily removed the cancellation check after `sleep`. Both debounce tests failed, and they passed again once I put it back.
- **Flakiness:** I wanted to run the search tests 50 times in a row, but that command needed approval, so it didn't run. Every normal run passed.