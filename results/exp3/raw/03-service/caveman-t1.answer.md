The service layer is in place. `swift build` succeeds and `swift test` passes all 26 tests, none of which touch the real network. Nothing is committed.

**New files in `Sources/TMDBApp/Services/`**
- `MovieService.swift`: the protocol, with the four `async throws` methods you specified.
- `TMDBMovieService.swift`: implements the protocol by sending the existing `Endpoint` cases through `HTTPClient`. Its init is `init(client: any HTTPClient = TMDBClient())`.
- `ImageURLBuilder.swift`: nested `Size` enum and `url(path:size:)`. `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`, and a nil or empty path gives `nil`.

**New files in `Tests/TMDBAppTests/`**
- `MockMovieService.swift`: loads fixture data, records every call in `calls`, and throws `error` whenever it is set.
- `MovieServiceTests.swift`: tests `TMDBMovieService` against a stub `HTTPClient` that serves fixtures and records endpoints. It also checks that errors propagate, and it exercises the mock.
- `ImageURLBuilderTests.swift`: covers all four sizes, nil and empty paths, and a custom base URL.

I deleted `Services/.gitkeep` since the folder now has real files. The fixtures are untouched. I didn't add any SwiftUI, so no `#if os(iOS)` wrapping was needed.