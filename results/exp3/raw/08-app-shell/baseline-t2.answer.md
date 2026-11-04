The app shell is in place. `swift build` succeeds and `swift test` passes all 58 tests. The `#Preview` blocks compile but I haven't rendered them in Xcode, and I haven't run the app. Nothing is committed and the fixtures are untouched.

**What I added**
- **`RootView`**: a `TabView` with Popular, Search and Favorites, each in its own `NavigationStack`, and it injects `dependencies.favorites` into the environment. I removed the `NavigationStack`s from the three screens, so they now expect to be hosted in one.
- **`AppDependencies`**: all the required members.
  - `live()` builds the real `TMDBClient`, `TMDBMovieService` and `UserDefaultsFavoritesStore`.
  - `preview` uses a new `PreviewMovieService` (hard-coded movies, inline JSON for detail and credits) and a new `InMemoryFavoritesStore`. It makes no network calls and writes nothing to disk.
- **Shared views**: `LoadingView`, `EmptyStateView(title:systemImage:message:)` and `ErrorView(message:retry:)`. I also added a `ViewStateContent` helper that turns a `ViewState` into the right one of these views. All four screens, including the detail screen, now use it instead of their own versions.
- **Missing API key**: `live()` never crashes. Requests fail with `APIError.missingAPIKey`, and the screens show an `ErrorView` saying "The TMDB API key is missing." with a Try Again button.
- **Previews**: a `#Preview` for each screen (Popular, Search, Favorites, Detail, Root) plus the three shared views, using the preview dependencies.

**Duplication and dead code I removed**
- The error-message mapping lived on `MovieListViewModel` but the search and detail view models called it too. It is now `Error.userMessage` in `APIError.swift`.
- The poster image with its film-icon placeholder was copied in `MovieRowView` and `MovieDetailView`. It is now `PosterImage`.
- The `navigationDestination` for movie details was repeated in three screens. It is now `.movieDetailDestination(service:)`.
- `APIConfiguration` repeated the API base URL, so it now uses `TMDBApp.apiBaseURL`.
- I dropped the unused `imageURLBuilder` property from `MovieRowView`.

I added `AppDependenciesTests` with four tests: `live()` doesn't crash, the missing-key message, the preview service working offline, and preview search filtering.

I couldn't test the missing-key path end to end. `TMDBClient` reads `TMDB_API_KEY` from the environment, so a test of the live path would depend on the machine's settings. The test only checks the message text.

My first preview-search test failed with `localizedCaseInsensitiveContains` even though "incep" is in "Inception". I switched to `range(of:options: .caseInsensitive)`, which passes, but I didn't find out why the first version failed.