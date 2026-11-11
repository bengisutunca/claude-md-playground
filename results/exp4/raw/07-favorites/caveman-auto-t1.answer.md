Favorites are in. `swift build` succeeds with no warnings and `swift test` passes all 57 tests, 8 of them new. Nothing is committed and the fixtures are untouched.

**What I added**
- **`Services/FavoritesStore.swift`**: the `FavoritesStore` protocol and `UserDefaultsFavoritesStore`, with the exact signatures you specified. It saves the full `Movie` list as JSON under one key, in insertion order. If the stored data is missing or can't be read, `load()` returns `[]`.
- **`ViewModels/FavoritesViewModel.swift`**: `@MainActor @Observable`, with the API you specified. It loads from the store in `init` and saves after every `toggle` and `remove(at:)`. Movies are matched by `id`, so a copy of the same movie with slightly different fields still counts as one favorite and can't be added twice.
- **`Views/FavoritesView.swift`**: a list with swipe to delete, an empty state, and tapping a row opens the detail screen.
- **`Views/RootView.swift`**: there was no top-level view, so nothing could share the view model or show the favorites list. This adds tabs for Popular, Search and Favorites, creates the one shared `FavoritesViewModel`, and puts it in the environment with `.environment(favorites)`.

**What I changed**
- **`Movie`** is now `Codable`. I added an `encode(to:)` that matches the existing decoder. Release dates are saved as `"yyyy-MM-dd"` and keys in snake_case (via a new `JSONEncoder.tmdb`), so saved movies decode back with the existing `JSONDecoder.tmdb`.
- **`MovieDetailView`** now takes `init(movie:viewModel:)` because the heart button needs the whole `Movie`, and the view model only had its id. The toolbar heart reads the shared view model from the environment and toggles the favorite. The two places that open this screen, `MovieListView` and `SearchView`, pass the movie now.

**Tests (`FavoritesTests.swift`)**: these cover toggling on and off, persistence across new store instances on the same suite, insertion order, removal by offsets, and no duplicates. They also check that missing image paths and release dates (including an empty one) survive a save and load, and that different keys don't share data. Each test uses its own `UserDefaults` suite, which is deleted when the test ends. Test movies come from the fixtures, and nothing touches the network.

**Things to know**
- `RootView` isn't wired into an app entry point because the package doesn't have one. Whatever app uses it needs to create it with a service and `FavoritesViewModel(store: UserDefaultsFavoritesStore())`.
- `MovieDetailView` and `FavoritesView` expect the shared view model in the environment, so any preview or host that skips `RootView` must inject it or the view will crash.
- If the stored favorites data is ever corrupt, it loads as an empty list, and the next change overwrites the bad data.