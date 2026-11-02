The app shell is in place. `swift build` succeeds and all 58 tests pass: the 54 existing ones plus 4 new ones in `AppDependenciesTests.swift`. I haven't run the app or looked at any of the `#Preview` blocks, so the tab layout is untested visually.

**What I added**
- **`RootView`** (`Views/RootView.swift`): a `TabView` with Popular, Search and Favorites tabs. Each tab has its own `NavigationStack` and shares one movie-detail destination, and the favorites model is injected into the environment.
- **`AppDependencies`** (`Services/AppDependencies.swift`): has the required API.
  - `live()` builds the real client, service and `UserDefaults` favorites store once. Without `TMDB_API_KEY` it doesn't crash, and requests fail with `APIError.missingAPIKey`.
  - `preview` uses `PreviewMovieService` and `InMemoryFavoritesStore`, so it needs no network.
- **Shared views** in `Views/Components/`: `LoadingView`, `EmptyStateView(title:systemImage:message:)` and `ErrorView(message:retry:)`. Every screen now uses them.
- **Missing API key**: the error text is "The TMDB API key is missing." and appears in an `ErrorView` with a retry button.
- **Previews**: each screen has a `#Preview` using `AppDependencies.preview`.

**Cleanup**
- **Error messages**: the user-facing error text lived on `MovieListViewModel` but the other two view models borrowed it. It's now `APIError.message(for:)`.
- **Screen layout**: the three screens each had their own copy of the message/retry layout and their own detail-navigation code. Both are now shared, and the screens no longer create their own `NavigationStack`.
- **Base URL**: `APIConfiguration` had its own copy of the base URL. It now uses `TMDBApp.apiBaseURL`.

**Left alone:** `MovieDetailView` and `MovieRowView` still each define their own poster image with a placeholder. I didn't merge them. The dead-code check was a grep for unused names, and I found nothing to remove.

**Caveats**
- The missing-key test returns early if you have `TMDB_API_KEY` set in your environment or Info.plist, so it only checks that case when the key is absent.
- I didn't commit anything or touch the fixtures.