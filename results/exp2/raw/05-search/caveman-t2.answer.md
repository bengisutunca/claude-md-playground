Search added. `swift build` OK. `swift test`: 45 tests pass, including 7 new ones.

New files:
- `Sources/TMDBApp/ViewModels/SearchViewModel.swift`
- `Sources/TMDBApp/Views/SearchView.swift`
- `Tests/TMDBAppTests/SearchViewModelTests.swift`

How it works:
- **Debounce:** setting `query` cancels the previous task and starts a new one. It calls `sleep(debounce)`, then checks for cancellation before it calls the service. A superseded search never reaches the service.
- **Short queries:** fewer than 2 characters after trimming cancel the pending search and set `.idle`. The service is not called.
- **State:** the search shows `.loading` while pending. An empty result gives `.empty`. Errors give `.failed`, with text from `MovieListViewModel.message(for:)`.
- **`SearchView`:** the `.searchable` modifier works on macOS. `.textInputAutocapitalization` and `.autocorrectionDisabled` sit inside `#if os(iOS)`.
- **Tests:** they inject a no-op `sleep`, so none of them wait in real time. They cover a short query, a long query then a short one, rapid typing, the injected debounce value, `search_inception`, `search_empty` and the error state.

I did not commit anything. I did not touch the `Fixtures/` files.