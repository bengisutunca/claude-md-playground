Favorites are in. `swift build` succeeds and `swift test` passes all 54 tests. I removed one misleading comment from `FavoritesTests.swift` after that last run and did not re-run the tests. Nothing is committed.

- **Store:** `FavoritesStore` and `UserDefaultsFavoritesStore` are in `Services/FavoritesStore.swift`. `Movie` can't round-trip its own encoding, because its decoder expects TMDB date strings. So the store saves through a private `Record` type that holds all the `Movie` fields.
- **View model:** `FavoritesViewModel` is in `ViewModels/`. It loads in `init` and saves after every `toggle` and `remove`. Duplicates are matched by movie id.
- **Views:** `Views/FavoritesView.swift` has the list with swipe to delete and an empty state. The heart button in the `MovieDetailView` toolbar toggles the favorite.
- **`MovieDetailView` init:** it now takes a `movie: Movie` parameter, because the toggle needs the full `Movie`. I updated its callers in `MovieListView` and `SearchView`.
- **Tests:** `Tests/TMDBAppTests/FavoritesTests.swift` covers toggle on and off, persistence across store instances, order, removal, and no duplicates. Each test uses its own `UserDefaults` suite and removes it afterwards.

The package has no app root, so nothing creates or shares the `FavoritesViewModel` yet. The app's root must call `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))`. `FavoritesView` also isn't linked into any tab or navigation yet. Without the injection, `MovieDetailView` and `FavoritesView` will crash when shown.