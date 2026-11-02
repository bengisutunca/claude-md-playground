Favorites are in. `swift build` succeeds and `swift test` passes all 56 tests, including 7 new ones. I haven't run the UI, so the heart button and the swipe-to-delete list are only compile-checked.

- **Store:** `FavoritesStore` and `UserDefaultsFavoritesStore` are in `Services/FavoritesStore.swift`. The store saves the full `Movie` values as JSON, in insertion order, using the exact signatures you specified.
- **`Movie` encoding:** `Movie` was decodable only, so I added `Encodable` to `Models/Movie.swift`, plus a date-to-string helper in `JSONDecoder+TMDB.swift`. A saved movie decodes back equal to the original.
- **View model:** `FavoritesViewModel` loads from the store in `init` and saves after every change. It also drops duplicate ids if the stored data contains any.
- **Views:** `FavoritesView` has swipe-to-delete and an empty state. `MovieDetailView` has the heart toolbar button, which reads the shared view model from the environment.
- **Tests:** `Tests/TMDBAppTests/FavoritesTests.swift` covers toggle on/off, persistence across store instances, order, removal and no duplicates. It also checks a round trip of all fields and an empty store. Each test uses its own `UserDefaults` suite, removed afterward, and they load `popular_page1` through `Fixture.data`.

Two changes go beyond what you listed:
- **`MovieDetailView` init:** it now takes a `movie: Movie` argument, because the heart needs the full movie, not just its id. I updated its callers in `MovieListView` and `SearchView`.
- **New `RootView`:** the package had no root view to hold the shared view model, so I added `Views/RootView.swift`. It's a tab view (Popular, Search, Favorites) that injects the single `FavoritesViewModel` into the environment. Nothing in the package uses `RootView` yet, so your app target needs to show it.

Nothing is committed, and I didn't touch the fixtures.