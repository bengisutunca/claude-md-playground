Favorites are in, with a heart button on the movie detail screen. `swift build` succeeds on macOS and `swift test` passes all 55 tests across 10 suites, including the 6 new favorites tests. Nothing is committed.

**What I added**
- **`Services/FavoritesStore.swift`**: the `FavoritesStore` protocol and `UserDefaultsFavoritesStore`, with the exact signatures you specified. It saves the full `Movie` values as JSON under one key, in insertion order. If nothing is stored, or the stored data can't be read, `load()` returns an empty list.
- **`ViewModels/FavoritesViewModel.swift`**: loads the store's favorites in `init` and saves after every `toggle` or `remove(at:)`. Movies are matched by `id`, so a movie can't be added twice. Toggling a favorite off and on again moves it to the end of the list.
- **`Views/FavoritesView.swift`**: a list with swipe to delete, an empty state, and links to the detail screen. It reads the shared view model from the environment.
- **`MovieDetailView`**: a heart button in the toolbar (filled when the movie is a favorite, with an accessibility label). The view now takes `movie:` so it has a `Movie` to toggle, and I updated the calls in `MovieListView` and `SearchView`.
- **`Movie`**: now `Codable`. It's saved with the same keys and `yyyy-MM-dd` date format it's decoded with, so a saved movie reads back unchanged.

**Tests (`FavoritesTests.swift`)**
They cover toggle on/off, persistence across store instances on the same suite (full movie values, including the release date), order kept, removal, no duplicates, and that different keys don't interfere. Each test uses its own uniquely named `UserDefaults` suite and deletes it afterwards. The movies come from the `popular_page1` fixture, so nothing touches the network.

**One thing you need to do:** nothing creates the shared `FavoritesViewModel` yet. There's no app root in the package, so no view calls `.environment(...)`, and `MovieDetailView` and `FavoritesView` will crash if shown without it. Whatever builds the app shell needs to create one `FavoritesViewModel(store: UserDefaultsFavoritesStore())` and attach it with `.environment(favorites)`, and add `FavoritesView` (for example as a tab).