The service layer is in place. `swift build` succeeds, and `swift test` passes all 27 tests (nothing hits the real network). Nothing is committed, and I didn't touch the fixtures.

**New in `Sources/TMDBApp/Services/`:**
- `MovieService.swift` holds the protocol with the four `async throws` methods.
- `TMDBMovieService.swift` sends each call to `HTTPClient` using the matching `Endpoint` case. It takes `client: any HTTPClient = TMDBClient()`.
- `ImageURLBuilder.swift` builds `<baseURL>/<size>/<path>`. For example, `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`. A nil or empty path returns nil. I also made it accept a path without the leading `/`, which you didn't ask for.

**Tests:**
- `MockMovieService.swift` returns fixture data, or throws the `error` you set, and records every call. `popular(page: 2)` returns the page-2 fixture, and the other methods return the Inception fixtures.
- `MovieServiceTests.swift` tests `TMDBMovieService` against a mock `HTTPClient`. It checks the endpoint sent, the decoded result, and that errors propagate. It also tests `ImageURLBuilder` (all four sizes, nil and empty path) and `MockMovieService` itself.

I removed `Services/.gitkeep` since the folder now has files. Everything is internal, like the existing `HTTPClient` and models, and no iOS-only code was needed.