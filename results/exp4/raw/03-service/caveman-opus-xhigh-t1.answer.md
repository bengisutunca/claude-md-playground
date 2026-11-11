I added the service layer. `swift build` succeeds with no warnings, and `swift test` passes all 30 tests in 6 suites, the 18 earlier ones included. Nothing is committed and the fixtures are untouched.

**New files in `Sources/TMDBApp/Services/`**
- `MovieService.swift`: the protocol with the four `async throws` methods. It's marked `Sendable` because view models will call it from the main actor.
- `TMDBMovieService.swift`: maps each method to the existing `Endpoint` case and calls `client.send`. `init(client: any HTTPClient = TMDBClient())` is as specified. It doesn't change errors, so `APIError` values from the client reach the caller unchanged.
- `ImageURLBuilder.swift`: has the `Size` enum and `url(path:size:)`, which returns `nil` for a nil or empty path. `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`, and a path without a leading slash gives the same result.

**New files in `Tests/TMDBAppTests/`**
- `MockMovieService.swift`: the reusable mock. It records every call in `calls`, including calls that fail. If `error` is set, every method throws it; otherwise it returns fixture data:
  - `popular(page:)` returns `popular_page<page>`
  - `search` returns `search_inception` if the query contains "inception" (any case), otherwise `search_empty`
  - `detail` and `credits` return the `_27205` fixtures
- `MovieServiceTests.swift`: has a private mock `HTTPClient` that records the endpoints it receives. The tests check that each service method sends the right `Endpoint` and decodes the result, that a client error reaches the caller unchanged, and that the mock movie service works.
- `ImageURLBuilderTests.swift`: covers the default base URL, each of the four sizes, a path without a leading slash, nil and empty paths, and a custom base URL.

No test touches the real network.

**Limits of the mock:**
- Any page or movie ID without a fixture (popular page 3, or a detail ID other than 27205) throws `Fixture.FixtureError.missing` rather than returning data.
- The error setting covers all four methods at once, so a test can't make only `credits` fail while `detail` succeeds. That's easy to add if a view model test needs it.