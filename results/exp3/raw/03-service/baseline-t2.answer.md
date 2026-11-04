The service layer is in. `swift build` succeeds and `swift test` passes all 30 tests, with no real network calls. Nothing is committed, and the fixtures are untouched.

**Source files** (`Sources/TMDBApp/Services/`):
- **`MovieService.swift`:** the protocol with the four `async throws` methods.
- **`TMDBMovieService.swift`:** `TMDBMovieService(client: any HTTPClient = TMDBClient())`. Each method sends the matching `Endpoint` through the client.
- **`ImageURLBuilder.swift`:** the builder with nested `Size` (`w185`, `w342`, `w780`, `original`). It returns nil for a nil or empty path, and also for a path that is only slashes. A path without a leading `/` also works.
- **`.gitkeep`:** I deleted it, since the folder now has files.

**Test files** (`Tests/TMDBAppTests/`):
- **`MockMovieService.swift`:** returns fixture data, or a configured error. It records every call in `calls`, and the fixture names are overridable.
- **`TMDBMovieServiceTests.swift`:** uses a private mock `HTTPClient` that records endpoints. The tests check the correct endpoint is sent, fixture decoding, empty search results, and error propagation. There is also a test for `MockMovieService` itself.
- **`ImageURLBuilderTests.swift`:** covers all four sizes, the `/inception.jpg` at `.w342` example, nil and empty paths, a missing leading slash, and a custom base URL.

Beyond what you specified, I added `CaseIterable` to `Size` so the tests can loop over every size. The new types are internal, like the existing models and `HTTPClient`. I used no iOS-only SwiftUI modifiers, so there was nothing to wrap in `#if os(iOS)`.