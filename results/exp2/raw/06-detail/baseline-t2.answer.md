The movie detail screen is in. `swift build` succeeds on macOS and `swift test` passes all 49 tests. I haven't run the app, so the UI is untested beyond compiling. Nothing is committed.

**What changed**
- **`MovieDetailViewModel.swift`** (new): contains `MovieDetailContent` and `MovieDetailViewModel`, with the exact names and signatures you listed.
  - `load()` fetches detail and credits concurrently with `async let`. If either request fails, `state` becomes `.failed` with the same error message the list screen uses.
  - Cast is sorted by `order` and cut to 10. Directors are the crew members whose job is "Director".
  - `formatRuntime` gives 148 → "2h 28m", 120 → "2h", 45 → "45m", 0 → "0m". Negative input is treated as 0.
  - I also added `yearText`, which uses the existing release-year helper.
- **`MovieDetailView.swift`** (new): shows the backdrop, poster, title, tagline, rating, year, runtime, genres, overview, director(s) and a horizontal cast list. It has a loading spinner and an error state with a "Try Again" button.
- **`MovieListView` and `SearchView`**: each now wraps its content in a `NavigationStack`, uses `NavigationLink(value:)` on the rows, and has a `navigationDestination(for: Movie.self)` that opens the detail screen.
- **`MovieDetailViewModelTests.swift`** (new):
  - successful load with `movie_detail_27205` + `movie_credits_27205`;
  - failure of detail alone, credits alone, and both together, each giving `.failed`;
  - runtime formatting for 0, 1, 45, 59, 60, 61, 120 and 148 minutes.

**One thing to know:** both views now take a `service: any MovieService` argument so they can build the detail view model. Nothing else in the repo constructs these views, so no callers broke, but the app entry point will need to pass the service when it creates them.

The existing mock service can only make both requests fail together. For the "either request fails" tests I added a small test-only service in the new test file that fails detail or credits separately.