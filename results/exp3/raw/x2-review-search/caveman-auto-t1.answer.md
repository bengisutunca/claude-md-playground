I found no real race conditions. What I did find is one user-visible text bug, a few edge cases, and some gaps in the tests. Ordered by severity:

### 1. Medium: the "No Results" message shows the wrong query
**File:** `SearchView`, `.empty` case
**Problem:** The message reads the live `viewModel.query`, not the query that returned no results. Say "xyz" returns nothing and the user keeps typing "xyzw". For the 300 ms debounce, plus the time the request takes, the screen says *Nothing found for "xyzw"* before that search has even run.
**Fix:** Have `SearchViewModel` record the query that produced the current state, for example `private(set) var searchedQuery: String` set in `performSearch`. Another option is a payload on the case, `.empty(query:)`, but `ViewState` is shared with other view models, so a property on the view model is the smaller change. Then `SearchView` shows that instead of `query`.

### 2. Medium-low: changing only whitespace cancels and repeats the search
**File:** `SearchViewModel`, `query.didSet` / `queryDidChange()`
**Problem:** The `didSet` compares the raw strings, but the search uses the trimmed text. Typing "inception" and then a space (to start the next word) counts as a change. It:
- cancels any request in flight, so results arrive later,
- swaps the results for a spinner (`state = .loading`),
- sends the same request again.

**Fix:** Keep the last trimmed query that was scheduled. In `queryDidChange()`, return early if the new trimmed text is the same and the state isn't `.failed`.

### 3. Low-medium: Retry waits through the debounce and gives no feedback
**File:** `SearchViewModel.retry()` (called from `SearchView`'s `ErrorView`)
**Problem:** `retry()` calls `queryDidChange()`, so it waits 300 ms with the error screen still showing. Each extra tap restarts the wait, so tapping repeatedly keeps putting the request off.
**Fix:** Have `retry()` cancel `searchTask`, set `state = .loading` right away, and start `performSearch(trimmed)` without the sleep. Add a test for it.

### 4. Low: only the first page of results is ever loaded
**File:** `SearchViewModel.performSearch`
**Problem:** It always asks for `page: 1` and ignores `totalPages`. A broad query like "the" silently stops at 20 results.
**Fix:** If you want full results, reuse the paging approach from `MovieListViewModel` (`currentPage`/`totalPages`, `loadNextPageIfNeeded`, a counter to drop old responses). The query becomes part of that counter. Otherwise, write the one-page limit down as a decision.

### 5. Low: duplicate movie IDs aren't removed
**File:** `SearchViewModel.performSearch` → `SearchView`'s `List(movies)`
**Problem:** `List` identifies rows by `Movie.id`. If TMDB returns the same ID twice (it sometimes does), SwiftUI's behaviour is undefined: wrong rows, animation glitches. `MovieListViewModel` already removes duplicates; search doesn't.
**Fix:** Drop repeated IDs before setting `.loaded`, keeping the first one.

### 6. Low: `SearchView` holds a view model it doesn't own in `@State`
**File:** `SearchView`, `@State private var viewModel`
**Problem:** `RootView` owns the view model, which is already in `@State` there. Wrapping it in `@State` again means `SearchView` only ever uses the first instance it gets. Any later instance passed in is silently ignored. This works today only because `RootView` always passes the same object.
**Fix:** Use `@Bindable var viewModel: SearchViewModel`. That still supports `$viewModel.query` for `.searchable`.

### 7. Low: the minimum length blocks real single-character searches
**File:** `SearchViewModel.minimumQueryLength`
**Problem:** The check counts characters, so one-character titles ("M", "9", "X") and single-character Chinese/Japanese queries (e.g. "愛") can't be searched.
**Fix:** This is a product decision. Either allow 1 character (the debounce already limits request volume), or keep the rule and accept the limit.

### 8. Low: test gaps
**File:** `SearchViewModelTests`
**Problem:**
- `rapidTypingTriggersOneSearch` passes even with no debounce. The injected sleep does nothing, and earlier tasks are cancelled before they run, so the debounce is never actually tested.
- Nothing tests a request being cancelled mid-flight (an old response arriving after the query changed), `retry()`, or whitespace-only edits.
- `waitForSearch()` only waits for the task that exists when it's called. If the query changes while waiting, it returns when the cancelled task ends.

**Fix:**
- Add a mock whose `search` stays suspended until the test releases it. Use it to check that an old response never overwrites the state.
- Add tests for `retry()` and for whitespace-only edits.

### Checked and fine
- **Old responses overwriting newer state:** this can't happen. Everything runs on the `@MainActor`, the old task is cancelled immediately when the query changes, and `performSearch` checks `Task.isCancelled` after its `await`.
- **Cancelled network requests:** a cancelled `URLSession` request comes back as a transport error rather than a cancellation error, so the specific catch misses it. The general catch still checks `Task.isCancelled`, so it never shows a false error.
- **Short or cleared queries:** they cancel the work in flight and reset to `.idle` correctly.

I didn't create, change or run anything.