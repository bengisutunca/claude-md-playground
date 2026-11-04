The app shell is finished. `swift build` succeeds and `swift test` passes all 57 tests, including 3 new ones in `AppDependenciesTests.swift`. I haven't opened any of the new `#Preview` blocks in Xcode, so the layouts are unchecked.

**New**
- `RootView` is a `TabView` with Popular, Search and Favorites. Each tab has its own `NavigationStack`, and the favorites view model is injected into the environment. I removed the `NavigationStack` that each screen used to wrap itself in.
- `AppDependencies` builds the real client, service and favorites store once. `live()` doesn't read the API key at construction, so a missing `TMDB_API_KEY` doesn't crash. Each request fails with `APIError.missingAPIKey`, and the screen shows an `ErrorView` saying the key is missing and to set `TMDB_API_KEY`. I haven't run the app without a key to see that screen.
- `preview` uses a new `PreviewMovieService` with inline mock data and an in-memory favorites store (one favorite pre-filled). It makes no network calls. Both live in `Services/`.
- `LoadingView`, `EmptyStateView` and `ErrorView` replace the ad-hoc `ProgressView` and `Text` versions. Popular, Search, Favorites and the detail screen all use them.
- Every screen has a `#Preview` using `AppDependencies.preview`.

**Cleanup**
- The error-to-message mapping was `MovieListViewModel.message(for:)`, which the Search and Detail view models also called. It's now `APIError.message(for:)`.
- The poster/placeholder image code was copied in `MovieRowView` and `MovieDetailView`. It's now one `PosterImageView`.
- `APIConfiguration` now uses `TMDBApp.apiBaseURL` instead of repeating the URL literal.
- The unused `imageURLBuilder` properties on the row and detail views are gone.

I left `Movie.year`/`ratingText` and their copies on `MovieDetail` alone. They're two small one-liners on separate types, so merging them wasn't worth a new abstraction.

Nothing is committed, and the fixtures are untouched.