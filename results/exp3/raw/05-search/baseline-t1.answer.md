Movie search is in. `swift build` succeeds and `swift test` passes all 44 tests, including the new ones. I didn't commit anything.

**What I added**
- **`SearchViewModel`**:
  - Setting `query` cancels the previous search task and schedules a new one.
  - Each scheduled search calls the injected `sleep(debounce)` first, then checks for cancellation before it touches the service. A superseded search therefore never calls the service, even if the injected `sleep` ignores cancellation.
  - A query under 2 characters after trimming sets `state` to `.idle` and cancels any pending search.
  - A search moves `state` to `.loading`, then to `.loaded`, `.empty` (no results) or `.failed`.
  - The service gets the trimmed query.
  - `waitForSearch()` is there too, with the exact `init` signature you gave.
  - Errors use the existing `MovieListViewModel.message(for:)`.
- **`SearchView`**: uses `.searchable` bound to `query`. It shows results with `MovieRowView`, plus idle, loading, empty and error states. I didn't need any `#if os(iOS)` wrapping, and it builds on macOS.
- **`SearchViewModelTests`** (6 tests), all using a no-wait `sleep` and the existing `MockMovieService` with fixtures:
  - A short query makes no service call.
  - Rapid typing makes one search.
  - `search_inception` loads results.
  - `search_empty` gives `.empty`.
  - A 401 gives the error state.
  - Clearing the query goes back to `.idle`.

`SearchView` isn't wired into any navigation yet, since you didn't ask for that.