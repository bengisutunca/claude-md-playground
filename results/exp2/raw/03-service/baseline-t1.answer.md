The service layer is in place. `swift build` succeeds and `swift test` passes all 29 tests. Nothing is committed, and I didn't touch the fixtures.

**Added in `Sources/TMDBApp/Services/`:**
- `MovieService.swift` is the protocol with the four async throwing methods.
- `TMDBMovieService.swift` implements it by sending the matching `Endpoint` through an injected `HTTPClient`. It defaults to `TMDBClient()`.
- `ImageURLBuilder.swift` has the nested `Size` enum and `url(path:size:)`. For example, `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`.
  - A nil, empty or `"/"` path returns nil.
  - A path without a leading slash also works.

**Added in `Tests/TMDBAppTests/`:**
- `MockMovieService.swift` is the reusable mock. It returns fixture data, or throws a configurable `error`, and records calls in `calls`. The recorded calls are thread-safe.
- `MovieServiceTests.swift` tests `TMDBMovieService` against a private mock `HTTPClient` and covers `ImageURLBuilder`. It checks:
  - **Endpoints and decoding:** each method sends the right endpoint and decodes its fixture.
  - **Errors:** a client error passes through unchanged.
  - **`ImageURLBuilder`:** all four sizes, nil and empty paths, no leading slash, and a custom base URL.
  - **`MockMovieService`:** it records calls and fails on demand.

The tests never touch the network, and no iOS-only SwiftUI code was needed.