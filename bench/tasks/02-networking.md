Add the networking layer in `Sources/TMDBApp/Networking/`:
- `APIConfiguration` holding the API key. Read it from the `TMDB_API_KEY` environment variable or, if absent, from the `TMDB_API_KEY` key of `Bundle.main` Info.plist. Never hard-code a key.
- `Endpoint` enum: `popular(page:)`, `search(query:page:)`, `movieDetail(id:)`, `credits(movieID:)`. It builds a `URLRequest` with `api_key` and `language=en-US` query items.
- `APIError`: `invalidResponse`, `httpStatus(code:message:)`, `decoding(Error)`, `transport(Error)`, `missingAPIKey`. Parse the TMDB error body (`status_message`) into `httpStatus`.
- `HTTPClient` protocol with `func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T`, and `TMDBClient` implementing it on an injected `URLSession`.
Add tests using a `MockURLProtocol` that serves fixtures: success decoding, the 401 error from `error_401`, a decoding failure, and query-item construction for each endpoint.


Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
