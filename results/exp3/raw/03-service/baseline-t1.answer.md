The service layer is in, `swift build` succeeds, and `swift test` passes all 28 tests, including the new ones.

**Source** (`Sources/TMDBApp/Services/`; I removed the `.gitkeep` there):
- `MovieService.swift` holds the `MovieService` protocol with the four `async throws` methods.
- `TMDBMovieService.swift` implements it on top of `HTTPClient`. The default client is `TMDBClient()`.
- `ImageURLBuilder.swift` builds `<base>/<size>/<path>`. A nil path, an empty path, or a path that is only `/` gives `nil`. `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`.

**Tests** (`Tests/TMDBAppTests/`):
- `MockMovieService.swift` returns fixture data or throws a configured `error`, and records calls in `calls`.
- `MovieServiceTests.swift` has two suites:
  - `TMDBMovieService` is tested with a private mock `HTTPClient`, so nothing touches the network. Each method is checked for the endpoint it sends and for decoding. Error propagation is checked too, and so is `MockMovieService`.
  - `ImageURLBuilder` is tested for the example URL, all four sizes, nil and empty paths, and a custom base URL.

I didn't commit anything and didn't touch the fixtures.