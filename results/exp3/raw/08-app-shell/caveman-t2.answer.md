The app shell is done. `swift build` succeeds and `swift test` passes all 57 tests, including 3 new ones in `AppDependenciesTests`. I didn't open the `#Preview` blocks in Xcode, so they are compiled but not looked at.

**What I added**
- **`RootView`:** a `TabView` with Popular, Search and Favorites tabs, each in its own `NavigationStack`. It injects `dependencies.favorites` into the environment.
- **`AppDependencies`:** it has the required API.
  - `live()` builds the real `TMDBClient`, `TMDBMovieService` and `UserDefaultsFavoritesStore`.
  - `preview` uses a new `PreviewMovieService` with inline mock data and an in-memory favorites store, so it needs no network.
- **`LoadingView`, `EmptyStateView`, `ErrorView`:** in `Views/StateViews.swift`, now used by every screen instead of the ad-hoc spinners and text.
- **Missing API key:** `live()` never touches the key, so it can't crash. Each request fails with `APIError.missingAPIKey`, and screens show an `ErrorView` saying to set `TMDB_API_KEY`.
- **Previews:** every screen has a `#Preview` using the preview dependencies.

**Duplication and dead code cleanup**
- The screens no longer wrap themselves in their own `NavigationStack`, since `RootView` provides it.
- The poster placeholder was copied in two views. It's now one `PosterImageView`, which also removed two unused `imageURLBuilder` properties.
- The error-to-message mapping lived on `MovieListViewModel` but was used by all three view models. It's now `APIError.userMessage(for:)`.
- `APIConfiguration` repeated the base URL. It now uses `TMDBApp.apiBaseURL`.

The new tests check that the preview service serves data without network access, that the preview list view model loads, and that `live()` doesn't crash and the missing-key message names `TMDB_API_KEY`. I didn't commit anything or touch the Fixtures.