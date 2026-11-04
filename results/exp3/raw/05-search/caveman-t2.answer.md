Movie search is added. `swift build` succeeds and `swift test` passes all 44 tests, including the 6 new search tests in `SearchViewModelTests.swift`. I haven't run the app, so `SearchView` itself is untested.

- **`SearchViewModel`:** this follows the API you specified. Each new `query` cancels the pending search task, and a search that was superseded or cancelled never calls the service or changes `state`. Queries under 2 characters after trimming set `.idle` without calling the service. A search goes `.loading`, then `.loaded`, `.empty` or `.failed`, with errors mapped through the existing `MovieListViewModel.message(for:)`.
- **`SearchView`:** it uses `.searchable` and shows results with `MovieRowView`. It also has idle, loading, empty and error messages. `.searchable` works on macOS, so I needed no `#if os(iOS)` wrapper.
- **Tests:** they use the mock service and an instant `sleep`, so none of them waits or touches the network. They cover:
  - a short query not calling the service;
  - a short query clearing results;
  - rapid typing triggering one search;
  - the `search_inception` result;
  - `search_empty` giving `.empty`;
  - the error state.

I didn't add a test that checks the injected `sleep` receives the debounce duration.

I didn't wire `SearchView` into any navigation. Nothing is committed, and the fixtures are untouched.