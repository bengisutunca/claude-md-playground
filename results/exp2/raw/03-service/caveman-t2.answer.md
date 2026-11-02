Service layer done. `swift build` succeeds and `swift test` passes (30 tests, 5 suites). Nothing committed.

Added in `Sources/TMDBApp/Services/`:
- `MovieService.swift`: the protocol, with the four `async throws` methods.
- `TMDBMovieService.swift`: implements it over `HTTPClient`, with `client` defaulting to `TMDBClient()`.
- `ImageURLBuilder.swift`: nested `Size` enum and `url(path:size:)`. A nil, empty or `"/"` path gives `nil`. A path without a leading slash also works.

Added in `Tests/TMDBAppTests/`:
- `MockMovieService.swift`: returns fixture data or a configured `error`, and records calls in `calls`.
- `MovieServiceTests.swift`: `TMDBMovieService` tests against a mock `HTTPClient`, `ImageURLBuilder` tests, and tests of `MockMovieService` itself. No test touches the network.

The types are internal, like the existing models and `HTTPClient`, so they are not `public`.