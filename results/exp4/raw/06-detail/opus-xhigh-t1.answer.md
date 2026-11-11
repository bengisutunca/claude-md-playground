The movie detail screen is in place and opens from both the Popular list and Search. `swift build` is clean and `swift test` passes all 57 tests. I haven't run the app, so the layout itself hasn't been checked by eye. Nothing is committed.

**What's new**
- **`MovieDetailContent`**: holds the detail, the top 10 cast sorted by `order`, and the directors. It has the helpers you asked for (`runtimeText`, `genresText`, `formatRuntime(minutes:)`), plus `releaseYear` and `directorsText`. Cast members with no `order` go last.
- **`MovieDetailViewModel`**: loads detail and credits at the same time with `async let`. If either request fails, the state becomes `.failed` with the same error messages the other screens use. As in `MovieListViewModel`, calling `load()` while a load is running or already done does nothing; calling it after a failure retries.
- **`MovieDetailView`**: shows everything you listed in that order, with a "Try Again" button on failure. The iOS-only title modifier is wrapped in `#if os(iOS)`.
- **Navigation**: both screens now wrap their own content in a `NavigationStack`, and rows link to the detail screen through `navigationDestination(for: Movie.self)`. The list and search view models each got a small `detailViewModel(for:)` method, so the views didn't need a new service parameter.

**Tests** (`MovieDetailViewModelTests.swift`)
- **Successful load** with the 27205 fixtures, checking the cast, director, "2h 28m", the genre string and the year.
- **Failure** of detail, of credits, or of both, each giving `.failed`.
- **Runtime formatting**: 0, 1, 45 and 59 minutes, exact hours, mixed hours and minutes, and negative input.
- **Other checks**: retry after failure, the 10-person cap and ordering, director filtering, and that both requests really run at the same time. I confirmed the timing test fails if the two requests are made one after the other.
- **Mock change**: so one request can fail alone, I added optional per-request errors to `MockMovieService`. Existing callers are unaffected.

**Decisions to review**
- **Runtime 0 shows nothing.** TMDB sends 0 when the runtime is unknown, so the screen hides it instead of showing "0m". `formatRuntime(minutes: 0)` still returns "0m" as specified.
- **The views now own their navigation stack.** Whatever builds the app's top level (e.g. a tab bar) should place these two views directly, without another `NavigationStack` around them. Nested stacks break navigation.
- **Leaving mid-load resets the screen.** The HTTP client reports a cancelled request as a network error. If you leave the screen while it's loading, it goes back to its starting state instead of showing an error, so it loads fresh next time.