App shell done. `swift build` passes. `swift test` passes: 57 tests, 11 suites.

**New**
- `Views/RootView.swift`: `TabView` with Popular, Search, Favorites, each in its own `NavigationStack`. It injects `dependencies.favorites` into the environment.
- `Services/AppDependencies.swift`: `live()` builds `TMDBClient`, `TMDBMovieService` and `UserDefaultsFavoritesStore`. `preview` uses mock data. It also has `makeMovieListViewModel()` and `makeSearchViewModel()`.
- `Services/PreviewMovieService.swift`: offline sample data, no network.
- `InMemoryFavoritesStore` in `Services/FavoritesStore.swift`.
- `Views/LoadingView.swift`, `Views/EmptyStateView.swift` and `Views/ErrorView.swift` use the required signatures. All screens use them now.
- `Views/PosterImageView.swift`: shared remote image with a placeholder.
- `Tests/TMDBAppTests/AppDependenciesTests.swift`: three tests, covering `preview` data, preview view models, and `live()` with no key.

**Missing key**
`live()` doesn't crash. Requests fail with `APIError.missingAPIKey`, and the screens show `ErrorView` with "The TMDB API key is missing."

**Duplication removed**
- Ad-hoc `message(...)` helpers and `ProgressView` blocks in four views.
- The poster placeholder, which was copied in `MovieRowView` and `MovieDetailView`.
- Three copies of `navigationDestination(for: Movie.self)`, now one `movieDetailDestination(service:)` modifier.
- A hard-coded base URL in `APIConfiguration`, now `TMDBApp.apiBaseURL`.

I found no dead code. Everything else is used by source or tests.

**Things to know**
- The three screen views no longer wrap themselves in a `NavigationStack`. `RootView` and the previews provide it.
- All views have `#Preview` blocks on `AppDependencies.preview`.
- The live-key test returns early if `TMDB_API_KEY` is set, so it never hits the real network. With a key set, it passes without checking anything.
- A first version of the preview search filter used `localizedCaseInsensitiveContains`. A test showed it returning no match for "incep" against "Inception", so I switched it to `range(of:options: .caseInsensitive)`.
- I didn't commit, and I didn't touch `Fixtures/`.