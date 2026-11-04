The service layer is in place. `swift build` succeeds and `swift test` passes all 27 tests.

**Sources (`Sources/TMDBApp/Services/`)**
- `MovieService.swift` holds the protocol with the four `async throws` methods.
- `TMDBMovieService.swift` implements it by calling `HTTPClient.send` with the matching `Endpoint` for each method. Its initializer is `init(client: any HTTPClient = TMDBClient())`.
- `ImageURLBuilder.swift` has the nested `Size` enum and `url(path:size:)`. `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`. A nil, empty or bare `/` path returns `nil`, and a path without a leading slash also works.
- I removed the `.gitkeep` from `Services/`.

**Tests (`Tests/TMDBAppTests/`)**
- `MockMovieService.swift` returns fixture data. It throws the configured `error` when you set one, and records calls in `calls`. Its fixture names are overridable.
- `MovieServiceTests.swift` tests `TMDBMovieService` against a private `MockHTTPClient` that serves fixtures, so nothing touches the network. The tests check the endpoint each method uses, that the response decodes, and that client errors propagate. One test covers `MockMovieService` itself.
- `ImageURLBuilderTests.swift` covers all four sizes, nil and empty paths, a path with no leading slash, and a custom base URL.

I didn't touch the fixtures or commit anything.