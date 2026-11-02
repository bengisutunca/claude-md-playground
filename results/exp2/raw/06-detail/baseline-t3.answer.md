The movie detail screen is in. `swift build` and `swift test` both pass (49 tests, no failures). Nothing was committed, and I didn't touch the fixtures. I didn't run the UI itself, only built it and ran the tests.

- **View model:** `MovieDetailViewModel` and `MovieDetailContent` are in `ViewModels/MovieDetailViewModel.swift`, with the exact API you specified.
  - **Loading:** `load()` fetches detail and credits concurrently with `async let`. If either request fails, the state becomes `.failed`, using the same error messages as the list screen.
  - **Content:** Cast is the first 10 members ordered by `order`, and directors are the crew members whose job is "Director".
  - **Formatting:** `formatRuntime` gives "2h 28m", "2h", "45m" and "0m" for 148, 120, 45 and 0. A negative runtime is clamped to "0m".
- **Detail view:** `Views/MovieDetailView.swift` has the backdrop, poster, title, tagline, rating, year and runtime, genres, overview, director and a horizontal cast list. The one iOS-only modifier is wrapped in `#if os(iOS)`.
- **Navigation:** `MovieListView` and `SearchView` now each wrap their content in a `NavigationStack` and use `NavigationLink(value:)` with `navigationDestination(for: Movie.self)`. Their initialisers now take a `service: any MovieService` parameter so they can build the detail view model. Nothing else in the package constructs these views, but any caller you add will need to pass it.
- **Tests:** `MovieDetailViewModelTests.swift` covers:
  - a successful load using the two 27205 fixtures;
  - failure of both requests;
  - failure of only detail and only credits (each through a small stub service);
  - the runtime cases, including 0, under 60 and exact hours.

  No test touches the real network.