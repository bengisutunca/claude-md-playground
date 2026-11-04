Favorites are in. `swift build` succeeds and `swift test` passes all 54 tests, including the 5 new ones. I haven't run the UI, so the heart button and favorites list are compile-checked only.

**What changed**
- **Store** (`Services/FavoritesStore.swift`): the `FavoritesStore` protocol and `UserDefaultsFavoritesStore`, with the exact signatures you specified. It saves full `Movie` values as JSON through a private codable record, so `Movie` itself is unchanged. A saved list with duplicate ids is de-duplicated when loaded.
- **View model** (`ViewModels/FavoritesViewModel.swift`): `FavoritesViewModel` with the required API. `toggle` appends a new favorite at the end, and every change is saved immediately.
- **Favorites screen** (`Views/FavoritesView.swift`): a list with swipe to delete and an empty-state message. It reads the view model from the environment.
- **Detail screen**: `MovieDetailView` now has a heart toolbar button that toggles the favorite. It needs the `Movie`, so its initializer is now `init(movie:viewModel:)`. I updated the call sites in `MovieListView` and `SearchView`.
- **Tests** (`FavoritesTests.swift`): toggle on and off, persistence across store instances on the same suite, order kept, removal, and no duplicates. Each test uses a unique `UserDefaults` suite and removes it afterwards.

**Not wired up yet:** the package has no app root, so nothing creates the shared `FavoritesViewModel` or calls `.environment(...)` yet. `MovieDetailView` and `FavoritesView` will crash at runtime unless an ancestor view injects it.

`FavoritesView` is also not added to any tab or navigation yet.

Nothing is committed, and the fixtures are untouched.