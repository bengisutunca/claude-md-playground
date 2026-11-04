I only read `SearchViewModel.swift` and `SearchView.swift`. I didn't open `ViewState`, `MovieService`, or `SearchViewModelTests`, and I didn't run anything. The core cancellation logic looks sound. Findings are ordered by severity.

## Findings

### 1. Medium: "No Results" message follows the live query (`SearchView.content`)
- **Problem:** The `.empty` case builds its text from `viewModel.query`, not from the query that was searched. After a search for "xyzq" returns nothing, the user keeps typing. The text immediately says `Nothing found for "xyzqw"` during the debounce and loading gap, before any search for that text has run.
- **Fix:** Store the searched term in the view model and show that. For example, make the state `.empty` carry the query, or add `private(set) var lastSearchedQuery`, set in `performSearch`.

### 2. Medium: whitespace-only edits re-trigger a search (`SearchViewModel.query` / `queryDidChange`)
- **Problem:** The `didSet` guard compares the raw `query`. Changing "ab" to "ab " passes the guard, cancels the in-flight request, and runs the same search again. The user sees a loading flash and wasted network calls. It also affects trailing spaces typed between words.
- **Fix:** Compare the trimmed value against the last trimmed value that was searched or scheduled, and return early if they match. Keep `retry()` as a forced path that skips this check.

### 3. Medium: no pagination (`performSearch`)
- **Problem:** `service.search(query:page: 1)` is hard-coded. Any query with more than one page of results silently shows only the first page, and there is no "load more".
- **Fix:** Track `page` and `totalPages`. Append results when the last row appears. Guard against concurrent page loads and reset on a new query. If single-page results are intentional, document it.

### 4. Low–Medium: the list is replaced by a spinner on every search (`SearchView.content`, `performSearch`)
- **Problem:** `performSearch` sets `state = .loading`, so the `List` is swapped for `LoadingView` on every debounced keystroke. This causes flicker and loses scroll position. During the debounce itself the old results stay visible, which is inconsistent with that.
- **Fix:** Keep showing the previous results while loading, for example with a `.loading(previous:)` state or an overlay `ProgressView`. Only show the full-screen spinner when no results exist yet.

### 5. Low–Medium: `retry()` goes through the debounce and gives no immediate feedback (`SearchViewModel.retry`)
- **Problem:** `retry()` calls `queryDidChange()`, so the error view stays on screen for 300 ms with no response to the tap. A user may tap repeatedly. Each tap cancels and reschedules, so only the last one runs.
- **Fix:** Add a `startSearch(immediately: Bool)` path that skips the sleep and sets `.loading` synchronously.

### 6. Low: no immediate search on submit (`SearchView`)
- **Problem:** There is no `.onSubmit(of: .search)`. Pressing return still waits out the debounce, and a one-character query can't be forced.
- **Fix:** Add `.onSubmit(of: .search) { viewModel.retry() }`, using the immediate path from #5.

### 7. Low: the search task is not cancelled when the view model goes away (`searchTask`)
- **Problem:** The `Task` captures `self` strongly and nothing cancels it. The view model lives until the request finishes. If the user leaves the screen, the network call still runs to completion.
- **Fix:** Capture `[weak self]` in the task, and/or cancel it from the view with `.onDisappear`. Don't use `deinit` for this, because a `@MainActor` class can't touch its isolated state there.

### 8. Low: cancelled-request handling relies on `Task.isCancelled` (`performSearch`)
- **Problem:** Only `CancellationError` is caught explicitly. If `MovieService` throws `URLError(.cancelled)`, it falls into the generic `catch`. That is currently saved by the `guard !Task.isCancelled` check, so it is not a live bug. It depends on that guard staying in place, and the error is mapped by `userMessage` otherwise.
- **Fix:** Make the cancellation checks explicit, for example `catch let e as URLError where e.code == .cancelled`. Alternatively, add a generation counter so only the latest search can write `state`. The counter is more robust than relying on `isCancelled`.

### 9. Nit: view model construction in `SearchView`
- **Problem:** The `SearchView` initializer receives a view model built by the caller, as in the Preview with `makeSearchViewModel()`. If the parent re-evaluates its body, a new view model is created and thrown away each time, because `State` keeps only the first. The same applies to the `MovieDetailViewModel` built in the `navigationDestination` closure.
- **Fix:** Create view models lazily inside the owning view, or cache them in `AppDependencies`.

## Suggested test additions (`SearchViewModelTests`)
- Typing "ab" then "ab " should result in a single service call.
- Out-of-order responses, where the first request finishes after the second, should not overwrite newer state.
- Shortening the query while a request is in flight should end in `.idle`, not in stale results.
- A retry after a failure should go straight to `.loading`.