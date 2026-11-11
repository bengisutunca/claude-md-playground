I found no crashes and no stale-result races, but there are three medium issues and several smaller ones. The cancellation logic holds up: every state write after an `await` in `SearchViewModel.performSearch` checks `Task.isCancelled` on the main actor. So a slow older response can't overwrite a newer one, even when `URLSession`'s cancellation comes back wrapped as `APIError.transport`. I found everything by reading the code; I didn't build or run the tests, since that would write build files.

## Medium

**1. Whitespace-only edits re-run the same search** — `SearchViewModel.queryDidChange` (`SearchViewModel.swift:43`)
- **Problem:** `didSet` compares the raw `query`, but the search uses the trimmed text. Typing "the " after "the" cancels and repeats an identical request: a 300 ms wait, a spinner, a network call. If the "the" request is still running, it gets thrown away and started again. This happens on every word boundary.
- **Fix:** Store the last scheduled trimmed query and return early in `queryDidChange` when it hasn't changed. `retry()` should skip that check with a `force` flag.

**2. Search only ever fetches page 1** — `SearchViewModel.performSearch` (`SearchViewModel.swift:61`)
- **Problem:** `page: 1` is hard-coded and `PagedResponse.totalPages` is ignored. For broad queries ("star", "love") users can only reach the first 20 results. `MovieListViewModel` does paginate, so the two tabs behave differently.
- **Fix:** Copy the `MovieListViewModel` approach: track `currentPage` and `totalPages`, add `loadNextPageIfNeeded(currentItem:)`, remove duplicate IDs across pages, and reset everything when the query changes. In `SearchView`, attach `.task { await viewModel.loadNextPageIfNeeded(currentItem:) }` to each row.

**3. Each refinement wipes the visible results** — `SearchViewModel.performSearch` (`SearchViewModel.swift:59`) and `SearchView.content`
- **Problem:** `state = .loading` replaces `.loaded`, so going from "incep" to "inception" removes the `List`, shows a full-screen spinner and loses the scroll position.
- **Fix:** Keep showing the previous `.loaded` results and add a separate `isSearching` flag for a small progress indicator. Use the full-screen `.loading` only when there's nothing to show yet.

## Low

**4. "No Results" names the wrong query** — `SearchView.content`, `.empty` case (`SearchView.swift:34`)
- **Problem:** The message reads the live `viewModel.query`, not the query that was searched. After "xyzq" returns nothing and the user types "a", the screen says *Nothing found for "xyzqa"* for 300 ms, before that query has been searched.
- **Fix:** Add a `private(set) var searchedQuery` set in `performSearch` (or attach the query to the empty state) and show that.

**5. The "type at least 2 characters" hint shows after 2 characters** — `SearchViewModel.queryDidChange` / `SearchView` `.idle` case
- **Problem:** From `.idle`, typing "in" schedules a search but leaves the state at `.idle` for the 300 ms wait. The user has typed 2 characters and is told to type at least 2.
- **Fix:** When a valid query is scheduled while the state is `.idle`, set `.loading` (or a pending flag) straight away.

**6. `retry()` waits out the debounce, and repeated taps delay it further** — `SearchViewModel.retry` (`SearchViewModel.swift:39`)
- **Problem:** `retry()` goes through the 300 ms wait, so `ErrorView` and its "Try Again" button stay on screen. Each extra tap cancels the scheduled task and restarts the timer.
- **Fix:** Let `retry()` cancel the current task and call `performSearch` with no sleep, setting `.loading` right away. Use the same immediate path for the keyboard's Search key by adding `.onSubmit(of: .search)` in `SearchView`, which currently doesn't exist.

**7. A spurious `CancellationError` leaves the spinner on forever** — `SearchViewModel.performSearch` (`SearchViewModel.swift:64`)
- **Problem:** `catch is CancellationError { return }` doesn't check whether this task was actually cancelled. If a service throws `CancellationError` for a live task (for example, a caching layer that cancels a shared inner task), the state stays `.loading` with no retry button. `TMDBMovieService` doesn't do this today, but the `MovieService` protocol doesn't prevent it.
- **Fix:** Remove the special case and let the generic `catch` and its `guard !Task.isCancelled` handle it, or set `.failed` when `!Task.isCancelled`.

**8. `SearchView` re-wraps an injected view model in `@State`** — `SearchView.init` (`SearchView.swift:5-9`)
- **Problem:** `RootView` already owns the view model. `@State(initialValue:)` keeps the first instance it receives and silently ignores any later one. No visible bug today because the instance never changes, but swapping dependencies would leave the view on the old view model. `MovieListView` uses the same pattern.
- **Fix:** Use `@Bindable var viewModel: SearchViewModel`; `$viewModel.query` keeps working.

**9. Single-character titles can't be searched** — `SearchViewModel.minimumQueryLength` (`SearchViewModel.swift:7`)
- **Problem:** Titles such as "M", "X" or "9", and CJK titles where one character is a whole word ("乱"), can never be searched.
- **Fix:** Lower the minimum to 1 and rely on the debounce, or allow short queries when the user explicitly submits (see the `onSubmit` path in #6).

**10. Tests don't cover the race protection** — `SearchViewModelTests`, `MockMovieService`
- **Problem:** The mock returns instantly and `sleep` does nothing, so the `Task.isCancelled` checks after the network call (`SearchViewModel.swift:62` and `:67`) never run. Deleting them would not break any current test.
- **Fix:** Give `MockMovieService` responses the test can hold and release (for example, a continuation per query). Then add tests for:
  - a slow first response arriving after a fast second one,
  - a short query typed while a request is running (should end `.idle`),
  - a whitespace-only edit (no new request),
  - retrying from `.failed`.

## Minor

**11. The search task holds a strong reference to `self` and is never cancelled on teardown** — `SearchViewModel.queryDidChange` (`SearchViewModel.swift:51`)
- **Problem:** Harmless now, because `RootView` keeps the view model for the app's lifetime. If it ever becomes per-screen, in-flight requests would outlive it.
- **Fix:** Capture `[weak self]`, or cancel `searchTask` when the view disappears.

## Outside these two files
`Endpoint.queryItems` uses `URLComponents`, which doesn't percent-encode `+`, and servers usually read `+` as a space. A search for "Romeo + Juliet" would likely reach TMDB as "Romeo   Juliet". The usual fix is to replace `+` with `%2B` in `percentEncodedQuery` after setting `queryItems`.