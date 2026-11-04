Movie search is in. `swift build` succeeds and `swift test` passes all 45 tests, including the new ones.

The `SearchViewModel` signature and `query`/`state` match your spec.

- **`SearchViewModel`** (`ViewModels/SearchViewModel.swift`):
  - Setting `query` cancels the previous search task and schedules a new one. The new task calls the injected `sleep(debounce)`, checks for cancellation, then calls the service. A superseded search therefore never reaches the service.
  - A query under 2 characters after trimming cancels any pending search, sets `state` to `.idle` and doesn't call the service.
  - An empty result gives `.empty`, and errors reuse `MovieListViewModel.message(for:)`.
  - `waitForSearch()` returns once the scheduled search has finished.
- **`SearchView`** (`Views/SearchView.swift`):
  - It uses `.searchable` and shows results with `MovieRowView`, plus idle, loading, empty and error messages.
  - The iOS-only modifiers `.textInputAutocapitalization` and `.autocorrectionDisabled` are wrapped in `#if os(iOS)`.
  - I didn't add it to the app's navigation, because you didn't ask for that.
- **Tests** (`SearchViewModelTests.swift`):
  - They cover a short query not calling the service, rapid typing triggering one search, the `search_inception` result, `search_empty` giving `.empty`, and the error state.
  - Two extra tests check that clearing the query cancels a pending search and that the debounce duration is passed to `sleep`.
  - They use an instant fake `sleep` and the existing mock service, so there is no real waiting and no network.

I didn't commit anything or touch the fixtures.