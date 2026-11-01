Add favorites.
- `FavoritesStore` protocol and `UserDefaultsFavoritesStore` (injectable `UserDefaults` suite) that persists favorite movies (encode the `Movie` values, not only ids) and keeps insertion order.
- `FavoritesViewModel` (`@Observable`, `@MainActor`): `favorites`, `isFavorite(_:)`, `toggle(_:)`, `remove(at:)`.
- `FavoritesView` list with swipe to delete and an empty state.
- A heart button in `MovieDetailView` toolbar that toggles the favorite. Share one `FavoritesViewModel` through the SwiftUI environment.
Add tests: toggle on/off, persistence across store instances on the same suite, order kept, removal, no duplicates. Use a unique `UserDefaults` suite per test and clean it up.


Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
