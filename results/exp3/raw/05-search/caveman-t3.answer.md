Movie search is in. `swift build` succeeds, and `swift test` passes all 43 tests, including the five new ones. Nothing is committed, and I didn't touch the fixtures.

- **`SearchViewModel`** (`Sources/TMDBApp/ViewModels/`) has the required init, `query`, `state` and `waitForSearch()`.
  - Setting `query` cancels the previous search task and starts a new one that calls `sleep(debounce)` first. A superseded search never reaches the service, even when the injected `sleep` doesn't throw on cancel.
  - A query under 2 characters after trimming sets `state` to `.idle` and doesn't call the service.
  - Results map to `.loaded`, or `.empty` for an empty list.
  - Errors map to `.failed`, with the message from `MovieListViewModel.message(for:)`.
- **`SearchView`** (`Sources/TMDBApp/Views/`) uses `.searchable` and lists results with `MovieRowView`. It shows idle, loading, empty and error messages. The `.textInputAutocapitalization(.never)` call is inside `#if os(iOS)`.
- **Tests** (`Tests/TMDBAppTests/SearchViewModelTests.swift`) cover all five cases you listed. Debounce is tested without real waiting: the other tests use a no-op `sleep`, and the rapid-typing test uses a gate that holds the sleeps until released.

I didn't wire `SearchView` into any navigation or tab, because you didn't ask for it.