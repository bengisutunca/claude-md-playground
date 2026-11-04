The movie detail screen is in, and `swift build` and `swift test` both pass (49 tests). I haven't run the UI, so the views are only compile-checked.

**What's there**
- **View model:** `MovieDetailViewModel` loads detail and credits with `async let`. Either request failing gives `.failed`, using the existing `MovieListViewModel.message(for:)` text. It's in `ViewModels/MovieDetailViewModel.swift`, along with `MovieDetailContent` and `formatRuntime(minutes:)`.
- **Content:** `MovieDetailContent` takes the top 10 cast ordered by `order` (members with no `order` go last). Directors are the crew with `job == "Director"`. I also added a `year` helper.
- **View:** `Views/MovieDetailView.swift` shows backdrop, poster, title, tagline, rating, year, runtime, genres, overview, a horizontal cast list and the director(s). It has a "Try Again" button on failure. The `#if os(iOS)` guard is around `navigationBarTitleDisplayMode`.
- **Navigation:** `MovieListView` and `SearchView` now use `NavigationLink(value:)` and `navigationDestination(for: Movie.self)`.
- **Tests:** `MovieDetailViewModelTests` covers the successful load with the 27205 fixtures, failure of each request separately, top-10 cast ordering, and runtime formatting (0, 1, 45, 60, 61, 120, 148).

**Things that differ from what you might expect**
- **View initialisers changed:** `MovieListView` and `SearchView` now take a `service:` argument so they can build the detail view model. Any caller needs updating; I found none in the package.
- **Each list view owns its `NavigationStack`:** there's no app root in the package to put one in. If you add a root stack later, remove these two.
- **Mock service extended:** `MockMovieService` now has optional `detailError` and `creditsError`, so a test can fail one request and leave the other alone.
- **Nothing committed**, and the fixtures are untouched.