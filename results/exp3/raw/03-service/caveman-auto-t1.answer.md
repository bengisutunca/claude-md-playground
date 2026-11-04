The service layer is in place. `swift build` succeeds with no errors or warnings, and `swift test` passes all 29 tests across 6 suites (13 of them are new). Nothing is committed and the fixtures are unchanged.

**Added in `Sources/TMDBApp/Services/`**
- `MovieService.swift`: the protocol with your four `async throws` methods. It is also marked `Sendable` so view models can hold it across actors.
- `TMDBMovieService.swift`: a struct with `init(client: any HTTPClient = TMDBClient())`. Each method just calls `client.send` with the matching `Endpoint` and response type. Errors come from `HTTPClient` unchanged.
- `ImageURLBuilder.swift`: `ImageURLBuilder(baseURL:)` with the nested `Size` enum and `url(path:size:)`. A nil or empty path returns nil. Paths work with or without a leading slash, so `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`.

**Added in the test target**
- `Mocks/MockMovieService.swift`: returns data from the fixture files, or throws an error you set at init or later through `error`. Every call is recorded in `calls` as a `Call` value you can compare with `==`. Which fixture it returns:
  - `popular(page:)` loads `popular_page<N>`. Only pages 1 and 2 exist, so any other page throws a missing-fixture error.
  - `search` returns `search_inception` when the query contains "inception", otherwise `search_empty`.
  - `detail` and `credits` always return the 27205 fixtures, whatever id you pass.
- `Mocks/MockHTTPClient.swift`: returns a fixture or throws an error, and records the endpoints it was asked for. The `TMDBMovieService` tests use it, so they never touch the network.
- `ServiceTests.swift`:
  - `TMDBMovieService`: checks that each method hits the right endpoint and decodes the result, and that client errors come through unchanged.
  - `ImageURLBuilder`: covers the example URL, all four sizes, a path without a leading slash, nil and empty paths, and a custom base URL.
  - `MockMovieService`: two short tests covering the fixture data, call recording and the configured error.

The two mocks guard their recorded calls with `NSLock` and are marked `@unchecked Sendable`. I used a lock rather than Swift's `Mutex` because `Mutex` needs macOS 15 and the package targets macOS 14. I left `Services/.gitkeep` in place.