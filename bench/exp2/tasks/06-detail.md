Add the movie detail screen.
- `MovieDetailViewModel` (`@Observable`, `@MainActor`) initialised with a movie id. It loads `detail` and `credits` concurrently (`async let`) and exposes `ViewState<MovieDetailContent>`, where `MovieDetailContent` holds the detail, top 10 cast ordered by `order`, and the directors.
- Formatted helpers: runtime as "2h 28m", genres joined with ", ", release year.
- `MovieDetailView`: backdrop, poster, title, tagline, rating, runtime, genres, overview, horizontal cast list, director.
- Navigate to it from `MovieListView` and `SearchView` with `NavigationStack` and `navigationDestination`.
Add tests: successful load with `movie_detail_27205` + `movie_credits_27205`, failure of either request gives `.failed`, runtime formatting edge cases (0, under 60, exact hours).

Required API (keep these exact names and signatures; extra members are fine):
- `struct MovieDetailContent` with `detail: MovieDetail`, `cast: [CastMember]`, `directors: [CrewMember]`, `runtimeText: String?` and `genresText: String`.
- `static func formatRuntime(minutes: Int) -> String` on `MovieDetailContent`: 148 gives "2h 28m", 120 gives "2h", 45 gives "45m", 0 gives "0m".
- `@MainActor @Observable final class MovieDetailViewModel` with `init(movieID: Int, service: any MovieService)`, `state: ViewState<MovieDetailContent>` and `func load() async`.

Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
