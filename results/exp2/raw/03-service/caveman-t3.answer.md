Service layer is in, and `swift build` and `swift test` both pass (27 tests, all green). I didn't commit, and the fixtures are untouched.

Added in `Sources/TMDBApp/Services/`:
- `MovieService.swift`: the protocol with the four `async throws` methods.
- `TMDBMovieService.swift`: implements it on top of `HTTPClient`, with `client: any HTTPClient = TMDBClient()`.
- `ImageURLBuilder.swift`: a nested `Size` enum and `url(path:size:)`. A nil, empty, or `"/"`-only path returns `nil`. A path without a leading slash also works.

Added in `Tests/TMDBAppTests/`:
- `MockMovieService.swift`: returns fixture data, or throws a configured `error`, and records calls in `calls`.
- `MovieServiceTests.swift`: tests for `TMDBMovieService` and `ImageURLBuilder`, plus a small test that `MockMovieService` records calls and errors. `TMDBMovieService` is tested against a `MockHTTPClient` that serves fixtures, so nothing hits the network.

I removed `Services/.gitkeep`. No iOS-only modifiers were needed, so there are no `#if os(iOS)` guards.