Detail screen built. `swift build` succeeds and `swift test` passes (50 tests, including the new ones). Nothing is committed.

- **`Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift`:** holds `MovieDetailContent` and `MovieDetailViewModel`, with the required names and signatures. `load()` fetches detail and credits concurrently with `async let`. Cast is the top 10 by `order`, with a nil `order` sorted last. Directors are crew whose `job` is "Director".
- **`Sources/TMDBApp/Views/MovieDetailView.swift`:** shows the backdrop, poster, title, tagline, rating, year, runtime, genres, overview, director and a horizontal cast list. It has a "Try Again" button on failure, and the iOS-only title modifier is wrapped in `#if os(iOS)`.
- **`Tests/TMDBAppTests/MovieDetailViewModelTests.swift`:**
  - Successful load from the `27205` fixtures.
  - `.failed` when both requests fail, when only detail fails, and when only credits fails.
  - The cast cap of 10 and its ordering.
  - Runtime cases for 148, 120, 45, 0, 60, 61 and 59 minutes.

**Initializers changed:** `MovieListView` and `SearchView` now take a `service: any MovieService` argument so they can build the detail view model. No code in the repo constructs them, so nothing else needed updating.

**Navigation stack:** each of the two views now wraps its content in its own `NavigationStack`, because the repo has no root view. Rows are `NavigationLink(value: movie)`, and each stack has a `navigationDestination(for: Movie.self)` that opens the detail screen. If you add a shared root stack later, move the stack there.

**Untested:** the SwiftUI views are compiled but never rendered or run, so the navigation and layout are unverified.