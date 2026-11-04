The movie detail screen is in. `swift build` succeeds and `swift test` passes (48 tests). I haven't launched the app, so the new screens and navigation have only been compiled.

- **`MovieDetailViewModel` and `MovieDetailContent`** (new, in `ViewModels/MovieDetailViewModel.swift`):
  - `load()` fetches detail and credits with `async let`, so a failure in either gives `.failed` with the same error message mapping the list screen uses.
  - Content holds the top 10 cast ordered by `order` and the directors, i.e. crew whose job is "Director".
  - `runtimeText`, `genresText` and `formatRuntime(minutes:)` follow your examples (148 gives "2h 28m", 120 gives "2h", 45 gives "45m", 0 gives "0m").
  - The release year was already on `MovieDetail.year`, so I reused it.
- **`MovieDetailView`** (new, in `Views/MovieDetailView.swift`): backdrop, poster, title, tagline, rating, year and runtime, genres, overview, director, and a horizontal cast list. It shows a retry button on failure.
- **Navigation:** `MovieListView` and `SearchView` now wrap their content in a `NavigationStack`, and each row is a `NavigationLink(value:)` with a `navigationDestination` to the detail view. Each view also takes a `service` parameter that defaults to `TMDBMovieService()`.
- **Tests** (`MovieDetailViewModelTests.swift`):
  - A successful load of the 27205 fixtures.
  - Cast limited to the top 10 by order.
  - `.failed` when only detail fails and when only credits fail. The existing mock fails both requests together, so I added a small `PartialFailureService` in the test file.
  - Runtime formatting for 0, under 60, exact hours, and mixed values.

There is no app root in the package, so I put the `NavigationStack` inside each list view. If you later add a root stack that hosts them, remove these to avoid nesting two stacks.

I didn't commit anything or touch the fixtures.