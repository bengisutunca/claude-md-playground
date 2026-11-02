I read `SearchViewModel.swift` and `SearchView.swift` and didn't run anything or check the tests. I found no crash-level bug. The cancellation handling is mostly sound: `performSearch` runs inside the same `Task`, so its `Task.isCancelled` guards work, and a cancelled request can't overwrite newer state. The findings below are ordered by severity.

### 1. Medium: `SearchViewModel` re-searches when only whitespace changes
- **Problem:** `query.didSet` compares the raw string, but the search uses the trimmed one. Typing `"ab"` and then `"ab "` cancels the in-flight search, waits for the debounce again and re-requests the same text. If results were already showing, the UI flickers to `.loading` for nothing.
- **Fix:** Store `lastSearched` (the trimmed text). In `queryDidChange`, return early if the trimmed value equals it and the state isn't `.failed`. Alternatively, compare trimmed values in `didSet`.

### 2. Medium: `SearchViewModel` hides all results beyond the first page
- **Problem:** `service.search(query:page:)` is always called with `page: 1`, and nothing in the view model or the `List` loads more. Any query with more than one page of matches silently shows only the first.
- **Fix:** Track `page` and `totalPages`. Add `loadMoreIfNeeded(current:)`, triggered from the last row's `onAppear`. Guard it with a flag so it can't run twice, and drop its result if the query changed in the meantime.

### 3. Medium: `SearchView` flickers and loses scroll position
- **Problem:** `performSearch` sets `state = .loading` unconditionally. Each new query swaps the whole `List` for `LoadingView()`, so the list is rebuilt and its scroll position resets. During the debounce window, the stale results of the previous query are still shown with no indication.
- **Fix:** Keep the previous results while loading, for example `.loading(previous: [Movie]?)` or a separate `isLoading` flag that shows a `ProgressView` overlay. Only show the full-screen `LoadingView` when there is nothing to show.

### 4. Low–Medium: `SearchViewModel.minimumQueryLength` blocks valid short queries
- **Problem:** The minimum of 2 uses `trimmed.count`. One-character CJK titles (e.g. "金") and short titles like "Up" or "M" can't be searched with fewer than 2 characters. The `.idle` message says "Type at least 2 characters", which is correct but can't be bypassed.
- **Fix:** Add `.onSubmit(of: .search)` in `SearchView` that calls a `searchNow()` method. That method would skip the debounce and the length check, except for an empty query.

### 5. Low–Medium: `SearchView` "No Results" text shows the live query
- **Problem:** The `.empty` message reads `viewModel.query`, not the query that was searched. If the user types more after a no-result search, the text changes during the debounce to "Nothing found for ..." with a term that hasn't been searched yet.
- **Fix:** Keep the searched text in the state, for example `.empty(query:)`, or in a `private(set) var lastSearchedQuery`.

### 6. Low: `SearchViewModel.retry()` re-debounces and shows no loading state
- **Problem:** `retry()` goes through `queryDidChange()`, so the error view stays on screen for 300 ms with no feedback after the tap. There is also no way to retry if the query is already cleared; `retry()` just sets `.idle`.
- **Fix:** Add a `startSearch(immediately: true)` path that skips the sleep and sets `.loading` synchronously.

### 7. Low: `SearchView` rebuilds the detail view model on every body evaluation
- **Problem:** The `navigationDestination` closure creates a new `MovieDetailViewModel` on each evaluation. If `SearchView` re-renders while a detail screen is open, that detail can lose its state or refetch. The view also takes `service` separately from `viewModel` just for this.
- **Fix:** Create the detail view model through a factory from `AppDependencies`, as `makeSearchViewModel()` already does. Better, move `navigationDestination` up to `RootView` so it doesn't depend on `SearchView`'s state.

### 8. Low: `SearchViewModel` task lifecycle
- **Problem:** The `Task` captures `self` strongly and nothing cancels it when the view goes away. A pending search keeps the view model alive until the network call finishes. Also, `waitForSearch()` only awaits the latest task, so it can return while an older cancelled task is still unwinding. That doesn't matter in practice, but it can make tests flaky.
- **Fix:** Capture `[weak self]` in the task, and cancel `searchTask` from `.onDisappear` or a `cancel()` method.

### 9. Low: `SearchViewModel.performSearch` error handling
- **Problem:** `catch is CancellationError` covers Swift concurrency cancellation. A cancelled `URLSession` request throws `URLError.cancelled`, which falls into the generic catch. It is only handled correctly because of the `isCancelled` guard right after, so it's fragile if that guard is reordered or removed.
- **Fix:** Handle `URLError.cancelled` explicitly next to `CancellationError`.

### 10. Nit: `SearchView` accessibility and polish
- **Problem:** `.autocorrectionDisabled()` is only applied under `#if os(iOS)`. `.searchable` has no suggestions or recents, and `LoadingView` has no accessibility announcement.
- **Fix:** Add accessibility labels and announcements for the state changes. Apply `.autocorrectionDisabled()` unconditionally, since it's available on macOS too.