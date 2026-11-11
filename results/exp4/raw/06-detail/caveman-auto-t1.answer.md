The movie detail screen is in place, and you can reach it by tapping a movie in either the Popular list or Search. `swift build` succeeds on macOS with no warnings, and `swift test` passes all 51 tests in 10 suites. I haven't committed anything, and the fixture files are unchanged.

**What I added**
- **`ViewModels/MovieDetailViewModel.swift`**:
  - `MovieDetailContent` takes the detail and credits. It keeps the top 10 cast sorted by `order` (cast with no `order` go last) and keeps crew whose job is "Director".
  - It provides `runtimeText`, `genresText`, `releaseYear`, `directorsText` and `formatRuntime(minutes:)`.
  - `MovieDetailViewModel` loads detail and credits at the same time with `async let`. If either request fails, the state becomes `.failed`, with the same error messages the list screen uses.
  - Calling `load()` again does nothing once loaded or while a load is running. After a failure it retries.
- **`Views/MovieDetailView.swift`**: shows the backdrop, poster, title, tagline, rating, year and runtime, genres, overview, a sideways-scrolling cast list and the director(s). It has loading and error states with a "Try Again" button. The one iOS-only modifier is wrapped in `#if os(iOS)`.
- **Navigation**: `MovieListView` and `SearchView` each now have their own `NavigationStack`. Rows are `NavigationLink(value: movie)` with `.navigationDestination(for: Movie.self)`. To give the detail screen a service without changing the views' initialisers, `MovieListViewModel` and `SearchViewModel` each gained `detailViewModel(for:)`.

**Tests**
- New `MovieDetailViewModelTests.swift` covers:
  - a successful load from the two `27205` fixtures (cast, director, "2h 28m", genres, year "2010", and that both requests are made)
  - a detail failure and a credits failure each giving `.failed`
  - retry after a failure, and a second load after success making no new requests
  - runtime formatting for 0, 1, 45, 59, 60, 61, 120, 148 and 180 minutes
  - top-10 cast ordering and the director filter, using made-up credits.
- To fail just one request, I gave `MockMovieService` optional `detailError` and `creditsError`. Existing tests are unaffected.

**Decisions for you**
- **Runtime of 0**: `formatRuntime(minutes: 0)` returns "0m" as required. But `runtimeText` is `nil` when the runtime is missing or 0, because TMDB uses 0 for "unknown". So the screen hides it rather than showing "0m". If you'd rather show "0m", it's a one-line change.
- **`NavigationStack` placement**: each view now creates its own stack. If you later put these views inside a parent `NavigationStack`, you'd need to remove the inner ones.