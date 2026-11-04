Movie search is in. `swift build` succeeds and `swift test` passes all 45 tests, including the 7 new ones. Nothing is committed, and I didn't touch the fixtures.

- **`SearchViewModel`** (`Sources/TMDBApp/ViewModels/SearchViewModel.swift`): it uses the required API and signatures.
  - Setting `query` cancels the previous search task and starts a new one.
  - The new task calls `sleep(debounce)` and then checks for cancellation, so a superseded search never calls the service.
  - A query under 2 characters after trimming sets `state` to `.idle` and doesn't call the service.
  - An empty result gives `.empty`.
  - Errors reuse `MovieListViewModel.message(for:)`, so the wording matches the list screen.
- **`query` property:** I wrote its getter and setter by hand, using the Observation macro's `access` and `withMutation`. That way setting `query` can schedule a search without a `didSet`.
- **`SearchView`** (`Sources/TMDBApp/Views/SearchView.swift`): `.searchable` plus a list of `MovieRowView`. It has idle, loading, empty and error states. I didn't need any `#if os(iOS)` wrapper because it only uses cross-platform SwiftUI.
- **Tests** (`Tests/TMDBAppTests/SearchViewModelTests.swift`): they use the existing `MockMovieService` and an instant `sleep`, so there's no real waiting and no network. They cover:
  - a short query not calling the service
  - a short query clearing earlier results
  - rapid typing causing one search
  - the debounce value reaching `sleep`
  - the `search_inception` result
  - `search_empty` giving `.empty`
  - the error state

I didn't hook `SearchView` into `TMDBApp.swift`, since you didn't ask for it.