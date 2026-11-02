Favorites are in, and `swift build` and `swift test` both pass (54 tests, including 5 new favorites tests). I haven't run the UI, so the heart button and favorites list are untested beyond compiling.

**What I added**
- **Model:** `Movie` is now `Codable`. Its encoder writes dates as `yyyy-MM-dd`, using a new `TMDBDate.format`, so a plain `JSONEncoder`/`JSONDecoder` round-trips it.
- **Store:** `FavoritesStore` and `UserDefaultsFavoritesStore` are in `Services/FavoritesStore.swift`. It saves the full `Movie` values as JSON and keeps their order.
- **View model:** `FavoritesViewModel` in `ViewModels/` has the exact API you listed. It loads from the store in `init` and saves after every change. `toggle` appends a new favorite or removes an existing one by id, so there are no duplicates.
- **Views:** `FavoritesView` is a list with swipe to delete and an empty state. `MovieDetailView` gets a heart toolbar button once the details have loaded. I added `MovieDetail.movie` to convert the loaded detail into a `Movie` for it.
- **Tests:** `FavoritesTests.swift` covers toggle on/off, persistence across store instances, order, removal and no duplicates. Each test uses its own `UserDefaults` suite and removes it afterwards.

**Not wired up yet**
- Nothing in the package puts a `FavoritesViewModel` into the SwiftUI environment. `MovieDetailView` and `FavoritesView` read it with `@Environment`, so the app's root (outside this package) has to supply it. It needs `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))`. Without it, opening a detail screen will crash.
- `FavoritesView` isn't reachable from any existing screen. It takes the `MovieService` so rows can open the detail view, and it needs its own tab or button.

I didn't commit anything or touch the fixtures.