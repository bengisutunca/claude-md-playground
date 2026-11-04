Favorites are in. `swift build` succeeds and `swift test` passes all 53 tests, including the 4 new favorites tests. I haven't run the app, so the heart button and the swipe-to-delete list are untested in the UI. Nothing is committed.

- **Store and view model:** `UserDefaultsFavoritesStore` and `FavoritesViewModel` use the exact API you specified. The view model matches movies by `id`, which is what prevents duplicates.
- **Persistence format:** `Movie` is now `Codable`. Its `encode(to:)` writes the release date as `yyyy-MM-dd`, so saved movies decode back to equal values. I added a small `TMDBDate.string(from:)` helper for this.
- **Views:** The new `FavoritesView` has swipe-to-delete and a "No favorites yet." empty state. `MovieDetailView` has a heart toolbar button that toggles the favorite. It reads the shared `FavoritesViewModel` from the SwiftUI environment.
- **Tests:** `FavoritesTests` covers toggle on/off, persistence across store instances on the same suite, kept order, removal, and no duplicates. Each test uses its own `UserDefaults` suite and removes it afterwards.

- **Changed signature:** `MovieDetailView` now takes `movie:` as well as `viewModel:`, because the heart button needs the full `Movie`. I updated `MovieListView` and `SearchView` to pass it.
- **Not wired up:** The package has no app root. Whoever hosts it must call `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))` and show `FavoritesView(service:)`. Without that environment value, `MovieDetailView` will crash.