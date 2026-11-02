Review is read-only. I read only `SearchViewModel.swift` and `SearchView.swift`, not `MovieService`, `ViewState` or the tests.

## High

**1. Stale task can leave the spinner stuck.** File: `SearchViewModel.swift`, `queryDidChange` and `performSearch`.
- `performSearch` sets `state = .loading` before any cancellation check.
- The `Task` checks `Task.isCancelled` and then hops to `performSearch`. If the query changes between those points, `queryDidChange` cancels the task and sets `state = .idle`. The stale task then runs and sets `.loading`.
- Nothing resets the state after that, so the spinner stays up with an empty query.
- The same window lets a stale task overwrite a newer `.loaded` state with `.loading`.
- Fix: put `guard !Task.isCancelled else { return }` as the first line of `performSearch`. Better, give each search a token (`searchID += 1`, capture it, compare before every state write). That makes `service.search` implementations that ignore cancellation safe too.

## Medium

**2. Whitespace-only edits trigger a new search.** File: `SearchViewModel.swift`, `query` `didSet` and `queryDidChange`.
- The guard compares raw `query`. Changing `"ab"` to `"ab "` cancels the search, debounces again, flashes `.loading` and refetches the same query.
- Fix: compute the trimmed text and return early when it equals the last searched or scheduled trimmed text. Keep that text in a stored property. `retry()` must bypass this check.

**3. `.loading` wipes the result list on every search.** File: `SearchViewModel.swift`, `performSearch`.
- Each new search replaces the list with `LoadingView`. Typing flickers, and the scroll position is lost.
- Fix: keep showing `.loaded` results while refreshing, for example with an `isLoading` flag or a `.loaded` state that carries a loading overlay. Show a full-screen spinner only when there are no results yet.

**4. Only page 1 is fetched.** File: `SearchViewModel.swift`, `service.search(query:page: 1)`.
- Results past the first page are unreachable. `SearchView` has no load-more trigger.
- Fix: track `page` and `totalPages`. Call `loadMore()` from `.onAppear` of the last row. Guard it against duplicate in-flight calls and against stale queries.

## Low

**5. The "No Results" message uses the live query.** File: `SearchView.swift`, `content` `.empty` case.
- The text reads `viewModel.query`, not the query that produced the empty result. While the user types, the message changes before the new search runs. It then names a query that was never searched.
- Fix: store `lastSearchedQuery` in the view model, or add it to the `.empty` state. Show that value.

**6. No immediate search on submit.** File: `SearchView.swift`, `.searchable`.
- Pressing return still waits for the 300 ms debounce.
- Fix: add `.onSubmit(of: .search) { viewModel.searchNow() }`. `searchNow()` skips the debounce.

**7. `retry()` waits for the debounce.** File: `SearchViewModel.swift`, `retry`.
- The user taps Retry and nothing happens for 300 ms.
- Fix: give `queryDidChange` a `debounced: Bool` parameter, and have `retry` pass `false`.

**8. Minimum length of 2 blocks one-character queries.** File: `SearchViewModel.swift`, `minimumQueryLength`.
- A single CJK character is a valid title search, for example "家". It is rejected, and the view shows the idle prompt.
- Also, `String.count` counts grapheme clusters, so the length rule is inconsistent across scripts.
- Fix: lower the minimum to 1, or make it locale-aware. If it stays, say so in the idle message.

**9. The task captures `self` strongly and nothing cancels it on teardown.** File: `SearchViewModel.swift`, `queryDidChange`.
- The closure calls `self.performSearch`, so the view model stays alive until the sleep and request finish.
- Fix: capture `[weak self]` and call `guard let self`. Cancel in an explicit `cancel()` method called from the view's `.onDisappear`. A `@MainActor` `deinit` cannot touch `searchTask` safely in all Swift versions.

**10. A new view model can be built on every parent re-render.** File: `SearchView.swift`, `init`.
- `State(initialValue:)` keeps only the first instance. Callers such as `makeSearchViewModel()` still build and discard one on each re-evaluation.
- Fix: pass a factory closure, or create the view model lazily in the parent with `@State`.

## Not verified

- Whether `MovieService.search` honors cancellation. If it throws `URLError(.cancelled)`, the `Task.isCancelled` guard in the generic `catch` already handles it.
- Whether `SearchViewModelTests` covers finding 1. A test with a controllable `sleep` and a service that suspends would reproduce it.