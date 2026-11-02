The service layer is in and its tests pass. `swift build` succeeds and `swift test` passes all 30 tests across 5 suites. I haven't committed anything or touched the fixtures.

**Source (`Sources/TMDBApp/Services/`)**
- `MovieService.swift` is the protocol with the four `async throws` methods.
- `TMDBMovieService.swift` implements it on `HTTPClient`, with `init(client: any HTTPClient = TMDBClient())`.
- `ImageURLBuilder.swift` has the nested `Size` enum and `url(path:size:)`.
- A nil or empty path returns nil. I also made a path of just `/` return nil, and a path without a leading slash still works.
- `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`.

**Tests (`Tests/TMDBAppTests/`)**
- `MockMovieService.swift` returns fixture data, or throws a configured `error` from every method, and records calls in `calls`. You can swap the fixture per method.
- `MovieServiceTests.swift` tests `TMDBMovieService` against a mock `HTTPClient` that only serves fixtures. It covers the endpoint each method uses, decoding, an empty search, error propagation and decoding failure. It also has one test for `MockMovieService` itself.
- `ImageURLBuilderTests.swift` covers all four sizes, nil and empty paths, a path with no leading slash, and a custom base URL.

I left out the `#if os(iOS)` wrapping because nothing I added uses SwiftUI.