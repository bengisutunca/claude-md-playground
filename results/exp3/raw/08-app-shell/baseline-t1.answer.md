The app shell is in place, and `swift build` and `swift test` both pass (58 tests). I haven't run the app or checked the `#Preview` blocks in Xcode, and nothing is committed.

**What I added**
- **`AppDependencies`:** it follows your required API. `live()` builds `TMDBClient`, `TMDBMovieService` and `UserDefaultsFavoritesStore`. `preview` uses a mock service and an in-memory favorites store, and returns a fresh instance each time.
- **`RootView`:** a `TabView` with Popular, Search and Favorites, each in its own `NavigationStack`. It creates the view models once and injects the favorites view model into the environment.
- **Shared views:** `LoadingView`, `EmptyStateView` and `ErrorView`, now used by all four screens. I also added a small `RemoteImage` for the poster placeholder.
- **Previews:** every screen has a `#Preview` using `.preview`, plus a "Missing API key" preview for the Popular list.
- **Missing API key:** with no key, `live()` still constructs and requests fail with `APIError.missingAPIKey`. The screen shows an `ErrorView` saying "The TMDB API key is missing. Set TMDB_API_KEY in the environment or Info.plist." I lengthened that message from the old wording, and no existing test checks it.
- **Mock data:** `PreviewMovieService` serves three built-in movies plus one detail and credits record for Inception, with no network access.
- **Tests:** a new `AppDependenciesTests.swift` covers the preview data, the missing-key message and `live()` not crashing.

**Duplication cleanup**
- The detail-screen navigation destination was copied in three views. It is now one `movieDetailDestination(service:)` modifier.
- The three hand-written message layouts and the loading spinners are replaced by the shared views.
- The poster placeholder was duplicated in two places and is now `RemoteImage`.
- `APIConfiguration` now uses `TMDBApp.apiBaseURL` instead of repeating the URL.
- The screens no longer create their own `NavigationStack`; `RootView` and the previews supply it.

**Left as is:** `MovieDetailViewModel` still calls `MovieListViewModel.message(for:)` for error text. It works, but the helper would sit better in a shared place.

I didn't find other dead code. The fixture files are untouched.