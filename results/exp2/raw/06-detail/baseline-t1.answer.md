The movie detail screen is in. `swift build` succeeds and `swift test` passes all 49 tests. I didn't run the app, so the SwiftUI layout hasn't been checked visually. Nothing is committed, and the fixtures are untouched.

**What was added**
- **View model:** `MovieDetailContent` and `MovieDetailViewModel` are in `ViewModels/MovieDetailViewModel.swift`, with the names and signatures you specified. `load()` fetches the detail and credits concurrently with `async let`.
- **Content rules:**
  - The cast is the first 10 members sorted by `order`.
  - Directors are the crew members whose job is "Director".
  - `formatRuntime(minutes:)` gives "2h 28m", "2h", "45m" and "0m" for your four cases.
  - A negative runtime is treated as 0.
- **Extra helper:** I added `yearText` to `MovieDetailContent`, which wraps the existing release-year property on `MovieDetail`.
- **Failures:** if either request fails, the state becomes `.failed` with the existing error message.
- **View:** `Views/MovieDetailView.swift` shows the backdrop, poster, title, tagline, rating, year, runtime, genres, overview, a horizontal cast list and the director. The iOS-only title-display modifier is wrapped in `#if os(iOS)`.
- **Tests:** `Tests/TMDBAppTests/MovieDetailViewModelTests.swift` covers:
  - a successful load using `movie_detail_27205` and `movie_credits_27205`;
  - the 10-person cast limit and ordering;
  - a failure of the detail request and a failure of the credits request;
  - runtime formatting for 0, 1, 45, 59, 60, 61, 120 and 148 minutes.

  The existing mock fails both requests together, so the either-request tests use a small fixture-backed stub in the test file. None of the tests touch the network.

**Initializer change to check:** `MovieListView` and `SearchView` now each wrap their content in a `NavigationStack`. Rows are `NavigationLink`s, and a `navigationDestination` opens `MovieDetailView`. Both initializers now take a `service: any MovieService` argument, `MovieListView(viewModel:service:)` and `SearchView(viewModel:service:)`, so they can build the detail view model. Any code outside the package that creates these views will need updating.