The app shell is finished. `swift build` is clean with no warnings, and `swift test` passes all 60 tests (54 existing plus 6 new). Nothing is committed and the fixtures are untouched.

**What's new**
- **`RootView`**: a `TabView` with Popular, Search and Favorites. Each tab sits in a small new `MovieNavigationStack`. It wraps the tab in a `NavigationStack`, opens `MovieDetailView` when a movie is tapped, and passes the shared favorites to every screen. That navigation code used to be copied into all three screens, and it was the only reason they took a `service:` argument. Now `MovieListView(viewModel:)`, `SearchView(viewModel:)` and `FavoritesView()` don't take one.
- **`AppDependencies`** (`Sources/TMDBApp/AppDependencies.swift`): has every member you specified, plus `makeMovieDetailViewModel(movieID:)`.
  - `.live()` builds the real `TMDBClient`, `TMDBMovieService` and the `UserDefaults` favorites store.
  - `.preview` uses a new `PreviewMovieService` with built-in sample data and an in-memory favorites store. The sample movies have no image paths, so previews don't download posters either.
- **`LoadingView`, `EmptyStateView`, `ErrorView`** (`Views/StateViews.swift`): built on SwiftUI's `ContentUnavailableView`. Every screen uses them, including the loading and error rows at the bottom of the Popular list.
- **Missing API key**: this already didn't crash, because the client looks up the key on each request and throws `APIError.missingAPIKey`. I made the message clearer: it now names `TMDB_API_KEY` and says to set it in the environment or Info.plist.
- **`#Preview`** blocks for RootView, Popular, Search, Favorites and Detail, all using `.preview`.

**Duplication and dead code removed**
- The error-to-message mapping lived on `MovieListViewModel`, and the Search and Detail view models reached into it. It's now a shared `error.userMessage`.
- The image-loading code with its placeholder was copied in the row and detail views; it's now one `TMDBImage` view. The unused `imageURLBuilder` properties are gone.
- The API base URL was written out a second time in `APIConfiguration`; it now uses `TMDBApp.apiBaseURL`.
- The Search screen hard-coded "2 characters" and trimmed the query itself; it now reads both from `SearchViewModel`.
- `FavoritesViewModel(store:)` and `TMDBMovieService(client:)` lost their default arguments, so only `live()` builds the real services. This also means a test can no longer write to the real `UserDefaults` by accident.

**New tests**
- The injected service and store are what the view models actually use.
- `.preview` returns sample data with no image paths.
- `live()` with no key fails with `APIError.missingAPIKey`, and the Popular screen shows that message. This test ran here because no key is set. On a machine where `TMDB_API_KEY` is set it skips itself, so it never calls the real API.
- The in-memory favorites store doesn't keep duplicates.

**Changes you might notice**
- `MovieDetail` now decodes in an extension so its memberwise initializer is available for the preview data. Decoding works exactly as before.
- When loading the next page fails, the bottom of the list now shows the full `ErrorView` rather than a small inline message, so it's bigger than before.

**Left as is**
- `Movie` and `MovieDetail` still each define the same `year` and `ratingText`. Sharing them would need a protocol for two one-line properties.
- "Try Again" after a next-page failure still reloads the list from page 1, as it did before.