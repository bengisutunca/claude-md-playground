The movie detail screen is in place, and you can open it from both the popular list and search. `swift build` succeeds and `swift test` passes all 49 tests in 10 suites. I haven't run the app itself, so the screen's layout is checked only by compiling, not by looking at it.

**What I added**
- **`ViewModels/MovieDetailViewModel.swift`**:
  - `MovieDetailContent` keeps the 10 lowest-`order` cast members and the crew whose job is `"Director"`. It has `runtimeText`, `genresText`, `releaseYear` and `formatRuntime(minutes:)` (148 → "2h 28m", 120 → "2h", 45 → "45m", 0 → "0m").
  - `MovieDetailViewModel` loads `detail` and `credits` at the same time with `async let`. If either request fails, the state becomes `.failed`, using the existing `MovieListViewModel.message(for:)` error text.
  - Calling `load()` while it's already loading, or after it has loaded, does nothing. Calling it after a failure tries again.
- **`Views/MovieDetailView.swift`**: backdrop, poster, title, tagline, rating, year and runtime, genres, overview, a horizontal cast list with photos and director(s). Loading shows a spinner; an error shows a "Try Again" button. The only iOS-only modifier is wrapped in `#if os(iOS)`.
- **`Views/RemoteImage.swift`**: I moved the image-with-placeholder code out of `MovieRowView` into this small view so the row and the detail screen share it.

**Navigation**
`MovieListView` and `SearchView` now each wrap their content in a `NavigationStack`. Rows are `NavigationLink(value: movie)` and open the detail screen through `navigationDestination(for: Movie.self)`.

**Decisions for you**
- **Init change:** both views' initialisers now take a `service: any MovieService`, which they need to create the detail view model. Nothing in the package called the old initialisers, but the views will need a service passed in wherever you create them.
- **Zero runtime:** `runtimeText` returns `nil` when the runtime is missing or 0, because TMDB uses 0 for "unknown" and showing "0m" would be misleading. `formatRuntime(0)` still returns "0m" as you specified.

**Tests** (`Tests/TMDBAppTests/MovieDetailViewModelTests.swift`)
- **Successful load** with `movie_detail_27205` and `movie_credits_27205`: checks the title, cast order, director, "2h 28m", the genres text, the year 2010, and that both requests were made.
- **Failures:** a failing detail request and a failing credits request each give `.failed`, and retrying after a failure loads.
- **Runtime formatting:** 0, 1, 45, 59, 60, 61, 120, 148 and 180 minutes.
- **Cast and directors:** with 12 cast members in shuffled order, only the top 10 are kept, sorted by `order`, and only directors are picked from the crew.

To make one request fail without the other, I added optional `detailError` and `creditsError` to `MockMovieService`; existing uses of the mock are unchanged. No fixture files were modified, and nothing is committed.