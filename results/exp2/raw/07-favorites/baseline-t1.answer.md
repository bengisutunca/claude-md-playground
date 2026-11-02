Favorites are in. `swift build` succeeds and `swift test` passes all 55 tests, including 6 new ones. I haven't run the app, so the heart button and the Favorites screen are untested beyond compiling.

**What changed**
- **Store and view model:**
  - `Services/FavoritesStore.swift` has the `FavoritesStore` protocol and `UserDefaultsFavoritesStore`. It saves the full `Movie` values as JSON, in insertion order.
  - `ViewModels/FavoritesViewModel.swift` loads from the store in `init` and saves after every `toggle` and `remove(at:)`. It also collapses duplicate ids found in stored data.
- **`Movie` is now `Codable`.** I wrote a custom `encode` so the saved JSON decodes with a plain `JSONDecoder`. Release dates are saved as `yyyy-MM-dd`, using a new `TMDBDate.format`.
- **`MovieDetail.movie`:** a new converter, because the detail screen only has a `MovieDetail`. A movie favorited from the detail screen therefore has the same fields as a list `Movie`, except that `genreIDs` comes from the detail's genres.
- **Views:**
  - `Views/FavoritesView.swift` is a list with swipe to delete and an empty state, and tapping a row opens the detail screen.
  - `MovieDetailView` has a heart toolbar button (`heart` / `heart.fill`) that appears once the details have loaded.
  - The detail view reads the shared `FavoritesViewModel` from the environment as an optional, so it doesn't crash when none is provided.
- **Tests:** `Tests/TMDBAppTests/FavoritesTests.swift` covers toggle on/off, persistence across store instances on the same suite, order, removal, no duplicates, and an empty store. Each test uses its own `UserDefaults` suite and removes it afterwards. The tests read the `popular_page1` fixture and make no network calls.

**You need to wire it up.** The package is a library with no app entry point, so nothing creates the shared `FavoritesViewModel` or shows `FavoritesView` yet. In your app, create one `FavoritesViewModel(store: UserDefaultsFavoritesStore())`. Inject it with `.environment(favorites)` at the root, and add `FavoritesView(service:)` as a tab.

I didn't commit anything or touch the Fixtures folder.