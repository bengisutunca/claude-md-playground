Add the service layer in `Sources/TMDBApp/Services/`:
- `MovieService` protocol: `popular(page:)` -> `PagedResponse<Movie>`, `search(query:page:)` -> `PagedResponse<Movie>`, `detail(id:)` -> `MovieDetail`, `credits(id:)` -> `Credits`.
- `TMDBMovieService` implementing it on top of `HTTPClient`.
- `ImageURLBuilder` that turns a TMDB path plus a size (`w185`, `w342`, `w780`, `original`) into a full URL under `TMDBApp.imageBaseURL`, returning `nil` for a nil path.
- A reusable `MockMovieService` in the test target that returns fixture data or a configured error, and records calls.
Add tests for `TMDBMovieService` (using a mock `HTTPClient`) and for `ImageURLBuilder`.

Required API (keep these exact names and signatures; extra members are fine):
- `MovieService` methods are all `async throws`: `popular(page: Int)`, `search(query: String, page: Int)`, `detail(id: Int)`, `credits(id: Int)`.
- `TMDBMovieService(client: any HTTPClient = TMDBClient())`.
- `ImageURLBuilder(baseURL: URL = TMDBApp.imageBaseURL)` with a nested `enum Size: String { case w185, w342, w780, original }` and `func url(path: String?, size: Size) -> URL?`. Example: `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`. A nil or empty path gives nil.

Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
