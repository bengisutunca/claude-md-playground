Movie search is in. `swift build` succeeds and `swift test` passes all 45 tests, including the 7 new ones. I didn't commit anything.

**What I added**
- `Sources/TMDBApp/ViewModels/SearchViewModel.swift`: setting `query` cancels the previous search task and schedules a new one. The task calls `sleep(debounce)` first, then checks whether it was cancelled before calling the service, so a superseded search never reaches it. A query under 2 characters after trimming sets `state` to `.idle` without calling the service.
- Results map to `.loaded`, an empty result to `.empty`, and errors to `.failed`. Error text comes from the existing `MovieListViewModel.message(for:)`.
- `Sources/TMDBApp/Views/SearchView.swift`: `.searchable` with `MovieRowView` rows, plus idle, loading, empty and error messages. The iOS-only placement and `textInputAutocapitalization` modifiers are wrapped in `#if os(iOS)`.
- `Tests/TMDBAppTests/SearchViewModelTests.swift`: short query doesn't call the service, a short query clears earlier results, rapid typing triggers one search, the debounce delay reaches `sleep`, `search_inception` loads, `search_empty` gives `.empty`, and a 401 gives the failed state. The tests inject a no-wait `sleep` and use `MockMovieService`, so nothing touches the network.

**Behaviours to know about**
- `state` is set to `.loading` as soon as a valid query is typed, before the debounce finishes.
- The service is called with the trimmed query, not the raw text.

One test failed to compile at first because I called `APIError.httpStatus` without its argument labels. I fixed the call and reran everything.