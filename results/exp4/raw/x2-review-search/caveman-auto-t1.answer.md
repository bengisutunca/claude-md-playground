I reviewed `SearchViewModel` and `SearchView`, plus the code they depend on (`ViewState`, `APIError.userMessage`, `TMDBClient`, `RootView`, `ErrorView`). I didn't change any files.

**No real race conditions.** The cancellation logic holds up. `SearchViewModel` is `@MainActor`, so a cancel in `queryDidChange()` can never interleave with a result being applied. `performSearch` checks `Task.isCancelled` after each `await`. A cancelled request is dropped whether it comes back as a `CancellationError` or as a `URLError.cancelled` wrapped in `APIError.transport`, and a stale task can't overwrite `.idle`. The problems below are about the screen showing the wrong thing and missing edge cases.

## Findings, most severe first

### 1. Medium: the "No Results" message shows the current text, not the query that was searched
- **File:** `SearchView`, the `.empty` case.
- **Problem:** The message reads `viewModel.query` live. When "xyzq" returns nothing and the user keeps typing "xyzqa", the screen says *Nothing found for "xyzqa"* before that query has been searched. More generally, the `.loaded`, `.empty` and `.failed` states keep showing the previous query's outcome for the whole 300 ms debounce, with no link to the query that produced them.
- **Fix:** Have `SearchViewModel` record the trimmed term each result belongs to, e.g. a `private(set) var searchedQuery: String` set in `performSearch`. Use that in the message instead of `query`.

### 2. Medium: edits that don't change the trimmed query still cancel and restart the search
- **File:** `SearchViewModel`, `query.didSet` and `queryDidChange()`.
- **Problem:** The `query != oldValue` check compares the raw text. Typing a trailing space ("matrix" to "matrix ") cancels the request in flight, waits through the debounce, sends the same request again and flashes the spinner. The same happens when the user deletes a character and retypes it.
- **Fix:** Compare trimmed values. Keep the last scheduled or completed trimmed term and return early if it's unchanged and the state isn't `.failed`. `retry()` should skip this check.

### 3. Medium-low: every new search replaces the results list with a full-screen spinner
- **File:** `SearchViewModel.performSearch` (`state = .loading`) and `SearchView`.
- **Problem:** The list disappears whenever the user refines the query, so the screen flickers on each pause in typing and the scroll position is lost.
- **Fix:** Only use `.loading` when nothing is shown yet. Otherwise keep `.loaded(old)` and expose a separate `isSearching` flag, shown as a small inline `ProgressView` or overlay. This matches how `MovieListViewModel.refresh()` keeps its movies while reloading.

### 4. Low: Retry and Return both wait out the debounce
- **Files:** `SearchViewModel.retry()` and `SearchView`.
- **Problem:** `retry()` goes through `queryDidChange()`, so tapping "Try Again" waits 300 ms before anything happens. Pressing Return in the search field doesn't search right away either, because there's no `.onSubmit(of: .search)`.
- **Fix:** Add a `searchNow()` that cancels the pending task and starts `performSearch` straight away. Call it from `retry()` and from `.onSubmit(of: .search)` in `SearchView`.

### 5. Low: only the first page of results is ever fetched
- **File:** `SearchViewModel.performSearch`, which calls `service.search(query:page: 1)`.
- **Problem:** Results stop at 20 with no sign that there are more. `response.totalPages` and `totalResults` are ignored.
- **Fix:** Add paging the same way `MovieListViewModel` does it: `loadNextPageIfNeeded`, a generation token, and removing duplicate IDs across pages so `List` doesn't get repeated IDs. If paging is out of scope, at least show "Showing 20 of N".

### 6. Low: the 2-character minimum blocks valid one-character titles
- **File:** `SearchViewModel.minimumQueryLength` and its check in `queryDidChange()`.
- **Problem:** `String.count` counts characters, so one-character titles in Chinese or Japanese (e.g. "愛") can never be searched.
- **Fix:** Lower the minimum to 1 (the debounce already limits request volume), or apply the 2-character rule only to ASCII text.

### 7. Low: the search task holds the view model alive and isn't cancelled when it's released
- **File:** `SearchViewModel.queryDidChange()`.
- **Problem:** The `Task` captures `self` strongly, and nothing cancels `searchTask` when the view model goes away. It's harmless today because `RootView` keeps the view model for the app's lifetime. If the view model is ever created per screen, though, an abandoned request still runs to completion.
- **Fix:** Capture `[weak self]` in the task (`guard let self else { return }` after the sleep), or cancel `searchTask` in an isolated `deinit`.

### 8. Low: `SearchView` claims ownership of a view model it's handed
- **File:** `SearchView.init`, `@State private var viewModel`.
- **Problem:** `RootView` already owns the view model in its own `@State`. Seeding a second `@State` from an argument only takes effect the first time, so if a different instance is passed later it's silently ignored.
- **Fix:** Declare `@Bindable var viewModel: SearchViewModel`. That still gives `$viewModel.query` for `.searchable`, and ownership stays in `RootView`.

## Test gaps
`SearchViewModelTests` passes a no-op `sleep`, so the debounce is never actually exercised. It's worth adding tests for:
- a whitespace-only change not starting a new search (#2);
- a slow first response arriving after a second query and being discarded;
- cancelling while `service.search` is in flight, so the search fails with a wrapped `URLError.cancelled` and the state must not end up `.failed`.