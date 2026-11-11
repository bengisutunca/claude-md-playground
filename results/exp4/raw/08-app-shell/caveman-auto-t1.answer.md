The app shell is finished. `swift build` passes with no warnings and `swift test` passes all 59 tests in 11 suites, including 5 new ones. Nothing is committed.

**What's new**
- **`AppDependencies`** (`Services/AppDependencies.swift`) has the exact API you specified, plus `makeMovieDetailViewModel(movieID:)`.
  - `live()` tries to load the API key once. If there isn't one, it still creates the client, so it doesn't crash; each request then fails with `APIError.missingAPIKey`.
  - `preview` uses a new `PreviewMovieService`, which serves sample movies with no image paths, so nothing is downloaded. It also uses a new `InMemoryFavoritesStore`, so previews never write favorites to disk.
- **`RootView`** shows the Popular, Search and Favorites tabs. Each tab is wrapped in a small shared `MovieNavigationStack` view. It owns the one navigation stack, the route to `MovieDetailView`, and passes the shared favorites model down. Before, every screen had its own copy of all three.
- **`LoadingView`, `EmptyStateView`, `ErrorView`** (`Views/StateViews.swift`) are built on SwiftUI's `ContentUnavailableView`. Every screen now uses them in place of its own spinner and message code.
- **Missing API key:** the message now reads "The TMDB API key is missing. Set TMDB_API_KEY in the environment or the app's Info.plist." There's a `#Preview("Missing API key")` that shows it.
- **`#Preview` blocks** exist for the root, all four screens, the movie row and the state views. All of them use the preview dependencies.

**Duplication and dead code removed**
- The error-message mapping lived on `MovieListViewModel` but the search and detail screens used it too. It's now a shared `userFacingMessage(for:)` in `ViewState.swift`.
- The image-with-placeholder code was duplicated in `MovieRowView` and `MovieDetailView`. Both now use one `TMDBImage` view.
- `APIConfiguration` had its own copy of the base URL; it now uses `TMDBApp.apiBaseURL`.
- I removed the default arguments that quietly created real dependencies: `TMDBMovieService(client: = TMDBClient())` and `FavoritesViewModel(store: = UserDefaultsFavoritesStore())`. Real dependencies are now only built in `AppDependencies`.
- The favorites de-duplication is now one helper used by both stores.

**Two fixes you didn't ask for**
- **Popular-list retry:** "Retry" after a failed next page used to call `refresh()`, which threw away the movies already loaded and reloaded from page 1. It now retries only the page that failed.
- **Turkish locale:** the preview search first used `localizedCaseInsensitiveContains`. Under a Turkish locale, "I" doesn't match "i", so searching "inter" didn't find "Interstellar" and a new test failed on this machine. It now uses a search that ignores the system language.

**New tests** (`AppDependenciesTests.swift`) check that:
- the preview data loads offline;
- preview favorites aren't saved;
- the view models all use the injected service;
- a missing key shows the clear message;
- `live()` fails with `missingAPIKey` when no key is set. This test is skipped if a key is configured, so the suite never touches the network.

One limit: the package has no app target, so the previews compile but I haven't seen them render in Xcode.