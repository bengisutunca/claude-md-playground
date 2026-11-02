Favorites are in. `swift build` succeeds and `swift test` passes all 55 tests, including 6 new ones. I haven't run the app or checked the heart button on a device.

- **Model:** `Movie` is now `Codable`. It encodes the release date as `"yyyy-MM-dd"`, using a new `TMDBDate.string(from:)` helper. I also changed `Movie` and `TMDBDate` (`Models/Movie.swift`, `Models/JSONDecoder+TMDB.swift`), which you didn't list.
- **Store:** `Services/FavoritesStore.swift` has the `FavoritesStore` protocol and `UserDefaultsFavoritesStore`, with the exact signatures you gave.
- **View model:** `ViewModels/FavoritesViewModel.swift` loads from the store in `init` and saves on every change. It treats two movies as the same favorite when their `id` matches.
- **Views:**
  - `Views/FavoritesView.swift` is a list with swipe to delete and a "No favorites yet." empty state.
  - `MovieDetailView` gets a heart button in the toolbar.
- **Tests:** `Tests/TMDBAppTests/FavoritesTests.swift` covers the five cases you listed plus a missing-key load. Each test uses its own `UserDefaults` suite and removes it afterwards.

- **Detail view signature:** `MovieDetailView.init` now takes `movie:` as well as `viewModel:`, because the heart needs the full `Movie`. I updated the call sites in `MovieListView` and `SearchView`.
- **Environment:** The detail view reads `FavoritesViewModel` from the environment as an optional, so it doesn't crash if nobody provides one. The heart only shows when a `FavoritesViewModel` is in the environment.
- **Not wired up:** The package has no app entry point, so nothing injects the view model or shows `FavoritesView` yet. The host app needs `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))` and a place to show `FavoritesView`.

Nothing is committed.