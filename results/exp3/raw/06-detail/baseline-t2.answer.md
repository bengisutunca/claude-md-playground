The movie detail screen is added. `swift build` succeeds on macOS and `swift test` passes (50 tests across 9 suites). Nothing is committed, and I didn't touch the fixtures.

**What's there**
- **View model:** `MovieDetailContent` and `MovieDetailViewModel` are in `Sources/TMDBApp/ViewModels/MovieDetailViewModel.swift`, with the API names and signatures you specified.
- **Loading:** `load()` fetches detail and credits concurrently with `async let`. If either request fails, the state becomes `.failed`.
- **Content:** The cast is the first 10 by `order`. Directors are the crew members whose job is "Director".
- **View:** `MovieDetailView` shows the backdrop, poster, title, year, tagline, rating, runtime, genres, overview, director and a horizontal cast list. The one iOS-only modifier is wrapped in `#if os(iOS)`.
- **Tests:** `MovieDetailViewModelTests` covers the successful load with the 27205 fixtures and `.failed` when either request fails. It also covers genre joining, the top-10 cast ordering, and runtime formatting for 148, 120, 60, 61, 45, 1 and 0 minutes. The existing mock fails both requests together, so the either-request tests use a small private service that fails one at a time.

**Changes to the existing views**
- `MovieListView` and `SearchView` now wrap their content in a `NavigationStack`. Rows are `NavigationLink(value: movie.id)`, and `navigationDestination(for: Int.self)` opens the detail view.
- To build the detail view model, both views' initialisers now take an extra `service: any MovieService`. Nothing in the repo constructs these views yet, so no call sites broke.
- Each view brings its own `NavigationStack`. If you later put both in a `TabView` this works as is. If you instead embed one inside another stack, you'll want to drop the inner one.

I didn't run the screens in a simulator; they've only been compiled, not seen.