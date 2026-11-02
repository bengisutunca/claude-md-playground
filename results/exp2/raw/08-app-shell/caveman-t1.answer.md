App shell done. `swift build` succeeds. `swift test` passes all 58 tests, 4 of them new.

**Added**
- `Views/RootView.swift`: `TabView` with Popular, Search and Favorites, each in its own `NavigationStack`. It owns the list and search view models and injects `dependencies.favorites` into the environment.
- `Services/AppDependencies.swift`: the required API.
  - `live()` builds `TMDBMovieService(client: TMDBClient())` and `UserDefaultsFavoritesStore`.
  - `preview` uses `PreviewMovieService` and an in-memory store.
- `Services/PreviewMovieService.swift`: offline sample movies, detail and credits. Poster paths are nil, so previews never fetch images. It also holds `InMemoryFavoritesStore`.
- `Views/StateViews.swift`: `LoadingView`, `EmptyStateView` and `ErrorView`, built on `ContentUnavailableView`. Every screen now uses them.
- Missing API key: `TMDBClient()` resolves the key on each request, so `live()` never crashes. Requests throw `APIError.missingAPIKey`, and the screen shows an `ErrorView`: "The TMDB API key is missing. Set TMDB_API_KEY and relaunch."
- `#Preview` blocks for `RootView`, `MovieListView`, `SearchView`, `FavoritesView`, `MovieDetailView` and the three state views.
- `Tests/TMDBAppTests/AppDependenciesTests.swift`: tests for preview data, the factory methods, the missing-key message, and that `live()` doesn't crash.

**Duplication and dead code removed**
- The `NavigationStack` in each screen is gone. `RootView` owns them.
- The `navigationDestination` block, copied three times, is now one `movieDetailDestination(service:)` modifier.
- The three ad-hoc `message(...)` helpers and `ProgressView` blocks are replaced by the shared state views.
- The `AsyncImage` and placeholder code, copied in the row and detail views, is now `RemoteImage`.
- `MovieListViewModel.message(for:)` moved to `Error.userMessage` in `APIError.swift`. Search and detail were calling it through the list view model. The message strings are unchanged except the missing-key one.
- `APIConfiguration` now defaults to `TMDBApp.apiBaseURL` instead of repeating the URL.
- I found no other dead code.

**Things to know**
- No `@main` App exists. The package is a library and its types are internal, so a host app target can't use `RootView(dependencies: .live())` yet. Say so if you want a public entry point.
- `SearchView` shows errors without a retry button, because `SearchViewModel` has no retry method.