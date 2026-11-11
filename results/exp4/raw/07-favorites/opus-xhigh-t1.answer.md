Favorites are in. `swift build` is clean with no warnings, and `swift test` passes all 58 tests, 9 of them new. The library also compiles for the iOS 17 simulator, so the `#if os(iOS)` code is checked too. Nothing is committed and the fixtures are untouched.

**What was added**
- **`Services/FavoritesStore.swift` and `Services/UserDefaultsFavoritesStore.swift`:** the protocol and the store, with your exact signatures. The store saves the full `Movie` values as one JSON array under `favorites.movies`, in the same shape as TMDB's API. If nothing is stored, or the data can't be read, `load()` returns `[]`.
- **`ViewModels/FavoritesViewModel.swift`:** `@MainActor @Observable`. It loads from the store in `init` and saves after every `toggle` and `remove(at:)`. Movies are matched by `id`, so the same movie from Popular and from Search counts as one. New favorites go to the end. Duplicates already in storage are dropped on load, and out-of-range offsets in `remove(at:)` are ignored.
- **`Views/FavoritesView.swift`:** a list with swipe to delete, a "No Favorites" empty state, and taps that open the movie's detail screen.
- **`Views/FavoriteButton.swift`:** the heart in the `MovieDetailView` toolbar. It reads the shared view model from the environment.

**Changes to existing code**
- **`Movie` is now `Codable`.** The new `encode(to:)` writes the release date as `yyyy-MM-dd` so it decodes back correctly. A time of day on that date isn't kept, but TMDB dates are whole days anyway.
- **`MovieDetailView` now uses `init(movie:service:)` instead of `init(viewModel:)`.** The heart needs the `Movie` value, and the screen used to know only its id. Both call sites, in `MovieListView` and `SearchView`, are updated.

**Tests (`FavoritesTests.swift`)**
They cover:
- toggling on and off
- full `Movie` values surviving a new store on the same suite, including nil poster, backdrop and release date
- insertion order
- removal
- no duplicates
- unreadable data
- stores with different keys staying separate

Each test creates its own `UserDefaults` suite and deletes it in `deinit`. The sandbox blocked me from reading `~/Library/Preferences`, so I couldn't confirm that no suite files are left on disk.

**Before you build the app shell:** there's no root view yet, so nothing injects the view model. The root needs to create one and pass it down, roughly like this:

```swift
@State private var favorites = FavoritesViewModel(store: UserDefaultsFavoritesStore())
// ...
TabView { ... }.environment(favorites)
```

Without that, the app crashes as soon as the Favorites tab or a detail screen opens.