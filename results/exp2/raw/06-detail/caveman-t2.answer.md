Detail screen done. `swift build` passes. `swift test` passes all 50 tests. I did not run the app, so the screen is untested visually.

- **View model:** `MovieDetailViewModel` and `MovieDetailContent` are in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift`. They use the required names and signatures. `detail` and `credits` load concurrently with `async let`. The content holds the top 10 cast by `order` and the directors (crew with job "Director"). Either request failing gives `.failed`.
- **Cast without `order`:** members with no `order` sort last.
- **View:** `Sources/TMDBApp/Views/MovieDetailView.swift` shows backdrop, poster, title, tagline, rating, year, runtime, genres, overview, a horizontal cast list and the director. The one iOS-only modifier, `navigationBarTitleDisplayMode`, is wrapped in `#if os(iOS)`.
- **Navigation:** `MovieListView` and `SearchView` each now own a `NavigationStack`. Rows are `NavigationLink(value: movie)`, and `navigationDestination(for: Movie.self)` opens the detail view.
- **Init change:** both views now need a `service` argument, so their inits changed. Nothing in the repo constructs them yet. Any future app entry point must pass the service in.
- **Tests:** `Tests/TMDBAppTests/MovieDetailViewModelTests.swift` covers:
  - a successful load with `movie_detail_27205` and `movie_credits_27205`;
  - failure of the detail request, of the credits request, and of both;
  - the 10-member cast cap and ordering;
  - runtime formatting for 0, 1, 45, 59, 60, 61, 120 and 148 minutes.

  The tests use the mock service, so none hit the network. I did not touch the fixtures and did not commit.