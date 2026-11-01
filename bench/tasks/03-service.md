Add the service layer in `Sources/TMDBApp/Services/`:
- `MovieService` protocol: `popular(page:)` -> `PagedResponse<Movie>`, `search(query:page:)` -> `PagedResponse<Movie>`, `detail(id:)` -> `MovieDetail`, `credits(id:)` -> `Credits`.
- `TMDBMovieService` implementing it on top of `HTTPClient`.
- `ImageURLBuilder` that turns a TMDB path plus a size (`w185`, `w342`, `w780`, `original`) into a full URL under `TMDBApp.imageBaseURL`, returning `nil` for a nil path.
- A reusable `MockMovieService` in the test target that returns fixture data or a configured error, and records calls.
Add tests for `TMDBMovieService` (using a mock `HTTPClient`) and for `ImageURLBuilder`.


Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
