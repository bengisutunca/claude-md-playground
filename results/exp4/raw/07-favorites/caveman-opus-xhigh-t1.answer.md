Favorites are in place. `swift build` succeeds, and `swift test` passes all 55 tests in 10 suites with no warnings. Nothing is committed and the fixtures are unchanged.

**What I added**
- **`Services/FavoritesStore.swift`**: the `FavoritesStore` protocol and `UserDefaultsFavoritesStore`, which saves the full `[Movie]` array as JSON under `favorites.movies`. Order is kept as stored.
- **`ViewModels/FavoritesViewModel.swift`**: loads the store's favorites in `init` and saves after every `toggle` or `remove(at:)`. Movies are matched by `id`, so the same movie coming from the popular list and from search counts as one favorite and is never added twice.
- **`Views/FavoritesView.swift`**: a list using the existing `MovieRowView`, with swipe to delete (`onDelete`) and a "No Favorites" empty state. Tapping a row opens the detail screen, the same way the other lists work.
- **`MovieDetailView`**: a heart button in the toolbar (filled when the movie is a favorite) that reads the shared view model from the environment. It has a "Add to / Remove from Favorites" label for VoiceOver.

**Changes to existing code**
- **`Movie` is now `Codable`.** Before, it could only be decoded, and its decoder reads the release date as a `"yyyy-MM-dd"` text field. I added a matching `encode(to:)` and a `TMDBDate.string(from:)` helper so saved movies load back exactly as they were. A test covers a movie with no release date and one with no poster.
- **`MovieDetailView` now takes `(movie:service:)` instead of `(viewModel:)`.** The heart needs the `Movie` itself, and this way it works before the details finish loading. I updated the two places that create it, in `MovieListView` and `SearchView`.

**Tests** (`FavoritesTests.swift`): toggle on/off, full movies persisting across store instances on the same suite, insertion order kept, removal, no duplicates, and unreadable saved data loading as empty. Each test gets its own `UserDefaults` suite, which is deleted afterwards.

**Things you should know**
- **Nothing creates the shared view model yet, because the app has no root view.** Whatever builds the root (presumably the app shell step) must create one and attach it, for example with `.environment(FavoritesViewModel(store: UserDefaultsFavoritesStore()))`. Without that, opening the favorites or detail screen crashes.
- **Unreadable saved data loads as an empty list,** and the next change overwrites it. The required `load()` signature can't report errors, so this was the only option.
- **Old test files need a manual delete.** My first two test runs left 12 empty `TMDBAppTests.favorites.*.plist` files in `~/Library/Preferences`. Clearing a suite empties it but leaves the file on disk, so the test cleanup now deletes the file too, and a later run left nothing behind. Deleting the 12 old files needed approval because they're outside the working directory, so you can remove them with:
  `rm ~/Library/Preferences/TMDBAppTests.favorites.*.plist`