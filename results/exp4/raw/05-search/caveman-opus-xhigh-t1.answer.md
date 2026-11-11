Movie search is in, and both `swift build` and `swift test` pass: 44 tests in 8 suites, 9 of them new. Nothing is committed, the fixtures are untouched, and no test uses the real network.

**What's new**
- **`SearchViewModel`** (in `Sources/TMDBApp/ViewModels/`) uses the exact API you specified.
  - Each change to `query` cancels the previous search task.
  - If the trimmed query is under 2 characters, `state` goes to `.idle` and the service isn't called.
  - Otherwise a new task waits `sleep(debounce)` first, then calls the service.
  - After the wait it checks whether it has been cancelled. This matters because a test's stand-in `sleep` may return normally instead of throwing. Since this all runs on the main actor, no newer query can sneak in between that check and the service call.
  - A replaced search never overwrites `state`, even if its service call was already running.
  - `waitForSearch()` waits on the current task, if there is one.
- **`SearchView`** (in `Views/`) uses `.searchable` and shows results with `MovieRowView`. The prompt, empty and error screens use SwiftUI's built-in `ContentUnavailableView`. It doesn't use any iOS-only modifiers, so no `#if os(iOS)` was needed.
- **Tests** in `SearchViewModelTests.swift`, using a stand-in `sleep` that returns immediately:
  - short queries (`""`, `"a"`, `"  a  "`, whitespace only) don't call the service;
  - a short query clears earlier results;
  - typing six queries quickly makes exactly one service call;
  - `search_inception` loads Inception, with the query trimmed and the 300 ms delay passed to `sleep`;
  - `search_empty` gives `.empty`;
  - a 401 error gives `.failed("Invalid API key.")`.

**One change outside the new files:** I moved the error-to-text function out of `MovieListViewModel` into a new shared `ViewModels/ErrorMessage.swift`, since both view models need it now. The popular list's behaviour hasn't changed. `MovieListViewModel.message(for:)` no longer exists; nothing else referred to it.

The rapid-typing test only checks the case where a search is replaced before its task starts. A replacement that arrives while the real `Task.sleep` is running hits the same cancellation path, but no test covers it, because that would need a controllable stand-in for `sleep`.