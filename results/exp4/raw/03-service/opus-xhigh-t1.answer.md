I added the service layer, and both `swift build` and `swift test` pass: 38 tests in 6 suites, with no failures. Nothing is committed and the fixture files are untouched.

**App code (`Sources/TMDBApp/Services/`)**
- **`MovieService.swift`**: the protocol, with the four `async throws` methods you specified. I marked it `Sendable` to match `HTTPClient`, so `@MainActor` view models can hold one safely.
- **`TMDBMovieService.swift`**: a thin wrapper over the client. Each method sends one request and passes errors through unchanged, so callers still get `APIError` cases. Search sends the query exactly as given; deciding to skip empty searches is left to the view models.
- **`ImageURLBuilder.swift`**: `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`. Beyond what you asked, it:
  - returns nil for whitespace-only paths and for `"/"`, not just nil or empty ones;
  - accepts paths without a leading slash;
  - handles a base URL that ends in a slash.
  
  I also made `Size` `CaseIterable` so the tests can loop over every size.

**Test code (`Tests/TMDBAppTests/`)**
- **`MockMovieService.swift`**: the reusable mock. For each call it checks, in order:
  1. If `error` is set, every method throws it.
  2. If that method's stub is set (`popularResult`, `searchResult`, `detailResult`, `creditsResult`), it returns that.
  3. Otherwise it returns fixture data: `popular_page<page>`, `search_inception` when the query contains "inception" (else `search_empty`), and `movie_detail_<id>` / `movie_credits_<id>`.
  
  It records every call in `calls`, including calls that throw, and has `resetCalls()`. Asking for a fixture that doesn't exist (say, page 3 or a movie other than 27205) throws a missing-fixture error. It's thread-safe so it works with the `Sendable` protocol.
- **`MockHTTPClient.swift`**: a stand-in for `HTTPClient` that records which endpoints were requested and answers from a handler, a fixture or an error. None of the tests touch the network.
- **`MovieServiceTests.swift`**: tests that each of the four methods sends exactly the right endpoint once, passes errors through, and decodes the fixture correctly. It also has a few tests for the mock itself, so later view-model tests can rely on it.
- **`ImageURLBuilderTests.swift`**: covers the example above, every size, the nil cases, a custom base URL, and real poster paths from `popular_page1` (Fight Club's null poster gives nil).
- **`FixtureLoader.swift`**: I added a `Fixture.decode(_:_:)` helper here, the only existing file I changed. It decodes a fixture the same way the app does.

None of these files use SwiftUI, so nothing needed `#if os(iOS)`.