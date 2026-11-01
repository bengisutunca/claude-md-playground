Add the movie detail screen.
- `MovieDetailViewModel` (`@Observable`, `@MainActor`) initialised with a movie id. It loads `detail` and `credits` concurrently (`async let`) and exposes `ViewState<MovieDetailContent>`, where `MovieDetailContent` holds the detail, top 10 cast ordered by `order`, and the directors.
- Formatted helpers: runtime as "2h 28m", genres joined with ", ", release year.
- `MovieDetailView`: backdrop, poster, title, tagline, rating, runtime, genres, overview, horizontal cast list, director.
- Navigate to it from `MovieListView` and `SearchView` with `NavigationStack` and `navigationDestination`.
Add tests: successful load with `movie_detail_27205` + `movie_credits_27205`, failure of either request gives `.failed`, runtime formatting edge cases (0, under 60, exact hours).


Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
