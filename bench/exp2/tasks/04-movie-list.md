Add the popular movies screen.
- `ViewState<Value>` enum shared by view models: `idle`, `loading`, `loaded(Value)`, `empty`, `failed(String)`.
- `MovieListViewModel` (`@Observable`, `@MainActor`) with `load()`, `refresh()` and `loadNextPageIfNeeded(currentItem:)`. It appends pages, stops at `totalPages`, ignores duplicate calls while a page is loading, and exposes a user-facing error message.
- `MovieListView` (List with poster thumbnail, title, year, rating) and `MovieRowView`. Use `AsyncImage` with a placeholder. Pull to refresh.
Add view model tests with `MockMovieService`: first load, pagination across `popular_page1` and `popular_page2`, end of pages, error state, refresh resetting pages.

Required API (keep these exact names and signatures; extra members are fine):
- `enum ViewState<Value>` with cases `idle`, `loading`, `loaded(Value)`, `empty`, `failed(String)`.
- `@MainActor @Observable final class MovieListViewModel` with `init(service: any MovieService)`, `state: ViewState<[Movie]>`, `func load() async`, `func refresh() async` and `func loadNextPageIfNeeded(currentItem: Movie) async`.
- Passing the last loaded movie as `currentItem` loads the next page, until `totalPages` is reached.

Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
