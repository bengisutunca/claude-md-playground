Detail screen done. `swift build` succeeds. `swift test` passes all 49 tests, including the new ones.

- **View model:** `MovieDetailViewModel` in `ViewModels/MovieDetailViewModel.swift`. It loads detail and credits with `async let`. If either request fails, `state` becomes `.failed`.
- **Content:** `MovieDetailContent` is in the same file. Cast is the top 10 by `order`, and directors are crew with `job == "Director"`.
- **View:** `Views/MovieDetailView.swift` shows backdrop, poster, title, tagline, rating, year, runtime, genres, overview, director and a horizontal cast list. iOS-only modifiers are wrapped in `#if os(iOS)`.
- **Tests:** `MovieDetailViewModelTests.swift` covers the `movie_detail_27205` + `movie_credits_27205` load and a failure of each request on its own. It also covers failure of both, and runtime formatting for 0, 1, 45, 59, 60, 61, 120 and 148 minutes. For the single-request failures I added a small private service stub in that test file, because `MockMovieService` can only fail both requests together.

**Breaking change:** `MovieListView` and `SearchView` now each wrap their content in a `NavigationStack` and register `navigationDestination(for: Movie.self)`. Their initialisers take an extra `service: any MovieService` argument, because the detail screen needs it. Nothing in the repo constructs these views yet, so nothing else changed.

I didn't commit anything or touch the fixtures.