The service layer is in place. `swift build` and `swift test` both pass: 28 tests in 6 suites, no warnings. Nothing is committed and the fixtures are unchanged.

**New files in `Sources/TMDBApp/Services/`**
- `MovieService.swift`: the protocol, with the four `async throws` methods you specified.
- `TMDBMovieService.swift`: `init(client: any HTTPClient = TMDBClient())`. Each method calls the matching `Endpoint` case (`.popular`, `.search`, `.movieDetail`, `.credits(movieID:)`) through `client.send`. Errors from the client (`APIError`) are passed through unchanged.
- `ImageURLBuilder.swift`: `init(baseURL: URL = TMDBApp.imageBaseURL)`, the nested `Size` enum and `url(path:size:)`. A nil or empty path returns nil. For example, `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`.

**New files in the test target**
- `MockMovieService.swift`: loads its default responses from the fixtures. Popular is keyed by page (pages 1 and 2), and asking for any other page throws. Search returns `search_inception`, and detail and credits return the 27205 fixtures.
  - It records every call in order in `calls`.
  - If you set `error`, every method throws it, but the call is still recorded.
  - Its `init` throws because it loads fixtures, so tests create it with `try MockMovieService()`.
  - Access to `calls` and `error` is lock-protected. The canned responses are not, so set them before handing the mock to the code under test.
- `ServiceTests.swift` has three suites:
  - **`TMDBMovieService`**, using a private `MockHTTPClient` that decodes a fixture or throws an error and records which endpoints were sent. It checks that each method sends the right endpoint and decodes the response, covers empty search results, and checks that client errors come through unchanged.
  - **`ImageURLBuilder`**: all four sizes, nil and empty paths, and a custom base URL.
  - **A small check of `MockMovieService` itself.**

No test touches the network.

I left the empty `Services/.gitkeep` placeholder in place.