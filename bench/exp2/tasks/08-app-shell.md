Finish the app shell.
- `RootView` with a `TabView`: Popular (`MovieListView`), Search (`SearchView`), Favorites (`FavoritesView`), each in its own `NavigationStack`.
- `AppDependencies` that builds the real `TMDBClient`, `TMDBMovieService` and favorites store once and injects them; a `preview` variant backed by mock data for SwiftUI previews.
- Reusable `LoadingView`, `EmptyStateView(title:systemImage:message:)` and `ErrorView(message:retry:)`, used by every screen instead of ad-hoc versions.
- When the API key is missing, screens show a clear `ErrorView` instead of crashing.
- Add `#Preview` blocks for each screen using the preview dependencies.
Review the whole package for leftover duplication and dead code, then make sure every test still passes.

Required API (keep these exact names and signatures; extra members are fine):
- `@MainActor final class AppDependencies` with `init(movieService: any MovieService, favoritesStore: any FavoritesStore)`, `movieService`, `favorites: FavoritesViewModel`, `static func live() -> AppDependencies`, `static var preview: AppDependencies`, `func makeMovieListViewModel() -> MovieListViewModel` and `func makeSearchViewModel() -> SearchViewModel`.
- `RootView(dependencies: AppDependencies)`, `LoadingView()`, `EmptyStateView(title: String, systemImage: String, message: String?)` and `ErrorView(message: String, retry: (() -> Void)?)`.
- `AppDependencies.live()` must not crash when `TMDB_API_KEY` is missing. Requests then fail with `APIError.missingAPIKey`.
- `AppDependencies.preview` serves mock data without any network access.

Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
