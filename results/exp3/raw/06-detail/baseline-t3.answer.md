The movie detail screen is in. `swift build` succeeds and `swift test` passes all 49 tests. I haven't run the app, so the views are only compile-checked.

- **View model:** `MovieDetailViewModel` is in `ViewModels/MovieDetailViewModel.swift`, along with `MovieDetailContent`. It loads detail and credits with `async let`. If either request fails, the state becomes `.failed`. Cast is the first 10 by `order`, and directors are the crew with job "Director". Runtime formatting gives "2h 28m", "2h", "45m" and "0m", as specified.
- **Detail view:** `MovieDetailView` shows the backdrop, poster, title, tagline, rating, runtime, year, genres, overview, director, and a horizontal cast list. It has a retry button on failure and no iOS-only modifiers outside `#if os(iOS)`.
- **Navigation:** `MovieListView` and `SearchView` now each wrap their content in a `NavigationStack`. Rows are `NavigationLink(value: movie)`, and each view has a `navigationDestination(for: Movie.self)`.
- **Changed initialisers:** both views now take a second argument, `makeDetailViewModel: (Int) -> MovieDetailViewModel`, so the caller supplies the service. Nothing in the repo constructs these views yet, so nothing broke.
- **Tests:** `MovieDetailViewModelTests.swift` covers a successful load from the 27205 fixtures, both requests failing, and each request failing on its own. It also checks runtime formatting for 0, 1, 45, 59, 60, 61, 120 and 148 minutes. No real network is used.

Nothing is committed, and I didn't touch the fixtures.