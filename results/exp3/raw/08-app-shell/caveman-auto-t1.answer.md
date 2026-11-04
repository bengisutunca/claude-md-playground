The app shell is finished. `swift build` succeeds with no warnings, and `swift test` passes all 57 tests in 11 suites. Nothing is committed and the fixtures are untouched.

**App shell**
- **`RootView`** (`Views/RootView.swift`): a `TabView` with Popular, Search and Favorites. Each tab has its own `NavigationStack` and a route to the movie detail screen. `RootView` creates the list and search view models once and passes the favorites model down to the screens.
- **`AppDependencies`** (`App/AppDependencies.swift`, a new `App/` folder): has the exact API you specified, plus `makeMovieDetailViewModel(movieID:)`.
  - `live()` uses the real TMDB client and saves favorites in `UserDefaults`.
  - `preview` uses a new `PreviewMovieService`, which serves sample movies from memory with no network, and an in-memory favorites store that starts with two favorites.
- **Shared state views** (`Views/StateViews.swift`): `LoadingView`, `EmptyStateView` and `ErrorView` are built on SwiftUI's `ContentUnavailableView`. Every screen now uses them in place of its own `message(...)` and `ProgressView` code. Search errors have no retry button, because changing the search text already retries.
- **Missing API key**: `live()` doesn't crash, because the client only looks up the key when it sends a request. Requests then fail with `APIError.missingAPIKey`. The screens show an `ErrorView` that says to set `TMDB_API_KEY` in the environment or the app's Info.plist.
- **Previews**: there is a `#Preview` for `RootView`, each tab screen, `MovieDetailView` and the state views, all using `.preview`.

**Duplication and dead code removed**
- The error-text mapping lived on `MovieListViewModel`, and the other view models borrowed it from there. It is now one shared `error.userMessage`.
- The poster/placeholder image code was copied in `MovieRowView` and `MovieDetailView`. It is now one `PosterImage` view.
- The detail-screen navigation was copied into three screens. It is now one `movieDetailDestination(using:)` helper.
- I removed default arguments that hid the real dependencies (`TMDBMovieService(client:)` and `FavoritesViewModel(store:)`), so `AppDependencies` is the only place that builds them.
- `APIConfiguration` had its own copy of the API URL; it now uses `TMDBApp.apiBaseURL`.
- `MovieDetail` now gets an automatic initializer for its fields, which the preview data uses.

**Tests**
- I added `AppDependenciesTests`, which checks:
  - `.preview` serves sample data for the list, detail and search screens.
  - `AppDependencies` uses the service and favorites store it is given.
  - `live()` with no key fails with `missingAPIKey` and the error message appears on screen. This test only runs when `TMDB_API_KEY` is not set, so it can never reach the real API.
- `localizedCaseInsensitiveContains("incep")` returned `false` inside the SwiftPM test process, so preview search uses `range(of:options: .caseInsensitive)` instead.

Two things left as they were:
- When loading the next page fails, the small "Retry" row at the bottom of the list reloads the whole list rather than just that page. It is a row inside the list, not a full-screen state, so it still has its own small layout.
- Like the rest of the package, `RootView` and `AppDependencies` are internal. A separate iOS app target would need them made `public` to use them.