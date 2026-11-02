The app shell is built. `swift build` succeeds and `swift test` passes all 58 tests. I didn't render the screens or the `#Preview` blocks, so none of the UI has been checked on screen.

- **`RootView`:** it has a `TabView` with Popular, Search and Favorites. Each tab sits in its own `NavigationStack`, and the favorites model is injected once there. The three screens no longer create their own stacks. I added a shared `movieDetailDestination` helper, so the detail navigation isn't repeated in each screen.
- **`AppDependencies`:** it follows the API you specified. `live()` builds `TMDBClient`, `TMDBMovieService` and `UserDefaultsFavoritesStore`. `preview` uses `PreviewMovieService` and an in-memory store, with no network. I also added `makeMovieDetailViewModel(movieID:)`.
- **Shared views:** `LoadingView`, `EmptyStateView` and `ErrorView` replace the hand-built versions on the list, search, favorites and detail screens.
- **Missing API key:** `live()` doesn't crash without `TMDB_API_KEY`. Requests fail with `APIError.missingAPIKey`, and the screens show an `ErrorView` saying to set `TMDB_API_KEY` in the environment or Info.plist.
- **Previews:** every screen has a `#Preview` using `AppDependencies.preview`.
- **Review cleanup:**
  - The poster/placeholder code that was duplicated in the movie row and detail view is now one `RemoteImageView`.
  - `APIConfiguration` now reuses `TMDBApp.apiBaseURL` instead of repeating the URL.
  - I found no other dead code.
- **Tests:** I added `AppDependenciesTests` covering `preview`, the injected store, and the missing-key error from `live()`. That last test skips its assertion if a key is configured on the machine, so it never hits the real network.

I changed the missing-key message text in `MovieListViewModel.message(for:)`. No existing test depended on the old wording.

I didn't commit anything or touch the fixtures.