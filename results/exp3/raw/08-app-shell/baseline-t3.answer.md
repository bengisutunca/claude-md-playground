The app shell is in place. `swift build` succeeds, and `swift test` passes all 59 tests, including the new ones I added. I couldn't render the SwiftUI previews or run the app here, so those are only compiled, not looked at. I haven't committed anything or touched the fixtures.

**What I added**
- **`RootView(dependencies:)`:** a `TabView` with Popular, Search and Favorites, each in its own `NavigationStack`. The screens no longer create their own stacks.
- **`AppDependencies`:**
  - **Live:** `live()` builds the real `TMDBClient`, `TMDBMovieService` and a favorites store backed by `UserDefaults`. It doesn't crash without `TMDB_API_KEY`; requests fail with `APIError.missingAPIKey`.
  - **Preview:** `preview` serves inline mock data with no network access, and its favorites live only in memory.
  - **Factories:** `makeMovieListViewModel()` and `makeSearchViewModel()` are included, plus the rest of the required API.
- **`LoadingView`, `EmptyStateView`, `ErrorView`:** every screen now uses these instead of its own text and spinner code. A missing key shows an `ErrorView` saying `TMDB_API_KEY` isn't set.
- **Previews:** one for each screen, plus extra ones for the missing-key and empty-favorites cases.
- **`AppDependenciesTests`:**
  - **Offline preview:** `AppDependencies.preview` serves mock data and doesn't persist favorites.
  - **Missing key:** `live()` fails with `missingAPIKey` when no key is set. That test returns early without asserting if a real key is configured, so it never touches the network.

**Duplication and dead code I cleaned up**
- Error-message mapping moved from `MovieListViewModel.message(for:)` to a shared `Error.userMessage`. The other two view models were reaching into the list view model for it.
- The `.movieDestination(service:)` modifier replaces three copies of the same `navigationDestination` block.
- `PosterImage` replaces two copies of the poster placeholder.
- The three private `message(...)` helpers are gone.
- `APIConfiguration` now uses `TMDBApp.apiBaseURL` instead of a duplicate URL literal.

I put `AppDependencies.swift` and `PreviewSupport.swift` in `Services/` and the shared views in `Views/Components/`, to stay within the existing folder layout. I didn't wire up an `@main` entry point, since the package is a library.