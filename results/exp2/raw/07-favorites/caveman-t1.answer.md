Favorites done. `swift build` clean. `swift test`: 56 tests pass, including 7 new ones in `Tests/TMDBAppTests/FavoritesTests.swift`.

- **`Movie` encoding:** `Movie` was `Decodable` only, so I added `Encodable` in `Models/Movie.swift`. It writes the same keys `init(from:)` reads. Release date goes out as `yyyy-MM-dd`, via new `TMDBDate.string(from:)`. I also added `Movie.init(detail:)`.
- **Store and view model:**
  - `Services/FavoritesStore.swift` has the protocol and `UserDefaultsFavoritesStore`.
  - `ViewModels/FavoritesViewModel.swift` loads in `init` and saves after every change. A duplicate is impossible because `toggle` removes a movie that is already a favorite.
- **Views:**
  - `Views/FavoritesView.swift` has the list, swipe to delete and an empty state.
  - `MovieDetailView` has a heart toolbar button, shown once the detail has loaded. It builds the `Movie` from the loaded `MovieDetail`.
- **Tests:** each test uses its own unique `UserDefaults` suite and removes it afterward. They cover toggle on/off, persistence across store instances, order, removal and no duplicates. Two extra tests cover a full `Movie` round trip and an empty store.

**Not wired up:**
- The package has no root view or app entry point. Whoever hosts it must call `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))`, for example on a `TabView` holding the list, search and `FavoritesView(service:)`.
- `MovieDetailView` and `FavoritesView` read the model with `@Environment(FavoritesViewModel.self)`. They crash if it is missing.

I did not commit anything.