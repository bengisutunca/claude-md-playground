Favorites are in. `swift build` succeeds and `swift test` passes all 54 tests, including the 5 new ones in `FavoritesTests.swift`. I didn't run the SwiftUI views, so the heart button and favorites list are compiled but not exercised.

- **Store and model:**
  - The store protocol and `UserDefaultsFavoritesStore` are in `Services/FavoritesStore.swift`.
  - `FavoritesViewModel` is in `ViewModels/FavoritesViewModel.swift` and loads in `init` and saves on every change. It matches movies by `id`, so there are no duplicates.
  - `Movie` is now `Codable`. It encodes the release date back to `"yyyy-MM-dd"`, so a saved movie decodes to the same value.
- **Views:** `FavoritesView` has the list, swipe to delete and the empty state. `MovieDetailView` has a heart toolbar button, shown once the detail has loaded. The button builds a `Movie` from the loaded detail.
- **Tests:** the five tests cover toggle on and off, persistence across store instances, order, removal and no duplicates. Each test uses its own `UserDefaults` suite and removes it afterwards. They read the `popular_page1` fixture and make no network calls.

**Not wired up yet:** the package has no app root, so nothing creates the `FavoritesViewModel` or injects it into the environment. Both `MovieDetailView` and `FavoritesView` read it with `@Environment(FavoritesViewModel.self)` and will crash without it. Whoever owns the app entry point needs to add `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))` and place `FavoritesView(service:)` in the UI.

A movie favorited from the detail screen is saved with its genre ids taken from the detail's genres, since `MovieDetail` has no `genreIDs`.

I didn't commit anything or touch the fixtures.