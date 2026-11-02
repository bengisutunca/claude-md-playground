The app shell is finished. `swift build` succeeds and `swift test` passes all 58 tests, including 4 I added. I haven't run the app or rendered any of the `#Preview` blocks, so the screens are untested beyond compiling. Nothing is committed, and I didn't touch the fixtures.

**What's new**
- **Root view:** `RootView(dependencies:)` has a `TabView` with Popular, Search and Favorites, each in its own `NavigationStack`. I removed the `NavigationStack` from the individual screens. The root view also injects the favorites model into the environment.
- **Dependencies:** `AppDependencies` has the required members, plus a `makeMovieDetailViewModel` that I didn't need and have since removed.
  - `live()` builds `TMDBClient`, `TMDBMovieService` and the `UserDefaults` favorites store.
  - `TMDBClient` only looks for the API key when a request is made. A missing key therefore doesn't crash and surfaces as `APIError.missingAPIKey`.
  - `preview` uses `PreviewMovieService` (three canned movies, detail and credits, no network) and `InMemoryFavoritesStore`.
- **Shared views:** `LoadingView`, `EmptyStateView(title:systemImage:message:)` and `ErrorView(message:retry:)` are in `Views/Components/`. Every screen uses them. A missing key shows `ErrorView` with "The TMDB API key is missing."
- **Previews:** every screen has a `#Preview` backed by `AppDependencies.preview`.
- **Tests:** `AppDependenciesTests` covers `preview` data, preview search, injected-service factories, and `live()` failing with the missing-key message. The `live()` check returns early if a `TMDB_API_KEY` is set in your environment.

**Cleanup**
- The three copies of the detail navigation destination are now one `movieDetailDestination(service:)` modifier.
- The poster placeholder was duplicated in the row and detail views. It's now one `RemoteImage` view.
- The duplicated rating formatting in `Movie` and `MovieDetail` now goes through `TMDBFormat.rating`.
- `APIConfiguration` now uses `TMDBApp.apiBaseURL` instead of repeating the URL.
- I found no dead code. `canLoadMore`, `releaseYear` and `ImageURLBuilder.Size.original` are only referenced by tests, so I left them.

**Things to know**
- `PreviewMovieService.search` matches titles with `range(of:options: .caseInsensitive)`. `localizedCaseInsensitiveContains` returned no matches for "incep" in the test run, and I didn't find out why.
- Search with fewer than 2 characters still shows an empty-state prompt rather than an error.