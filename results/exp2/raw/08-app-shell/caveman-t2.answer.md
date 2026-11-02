App shell done. `swift build` succeeds and `swift test` passes all 58 tests. I didn't render any of the SwiftUI previews or run the app.

**What I added**
- **`AppDependencies`**: in `Services/AppDependencies.swift`, with the required API. I put it in `Services/` to keep the existing folder layout.
- **Preview support**: `Services/PreviewSupport.swift` holds `PreviewMovieService` (canned data) and `InMemoryFavoritesStore`. `AppDependencies.preview` uses both, so it needs no network.
- **`RootView`**: three tabs, each in its own `NavigationStack`. The screens no longer create their own stacks. `RootView` also injects the favorites view model.
- **Shared state views**: `LoadingView`, `EmptyStateView` and `ErrorView` live in `Views/StateViews.swift`. All four screens use them in place of their ad-hoc versions.
- **Missing API key**: `live()` doesn't read the key, so it can't crash. Each request then fails with `APIError.missingAPIKey`, and the screen shows an `ErrorView` saying "The TMDB API key is missing."
- **Previews**: every screen has a `#Preview` using the preview dependencies.
- **Tests**: `AppDependenciesTests.swift` covers the preview service, the injected favorites store and the missing-key failure. The missing-key test returns early if `TMDB_API_KEY` is set in your environment.

**Duplication and dead code removed**
- The error-message mapping lived on `MovieListViewModel` but the search and detail view models also called it. It is now `APIError.userMessage(for:)`.
- The poster image with its placeholder was written twice. It is now `PosterImageView`.
- The `navigationDestination` for `Movie` was copied in three views. It is now a `movieDetailDestination(service:)` modifier, defined in `MovieDetailView.swift`.
- The rating format was duplicated in `Movie` and `MovieDetail`. Both use `TMDBRating.text`.
- `APIConfiguration` repeated the base URL literal. It now uses `TMDBApp.apiBaseURL`.
- The unused `imageURLBuilder` property is gone from `MovieRowView` and `MovieDetailView`.

`SearchView` shows its error with no retry button, because `SearchViewModel` has no retry method. Typing again re-runs the search.

I didn't commit anything or touch the Fixtures.