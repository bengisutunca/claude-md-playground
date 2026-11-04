The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 15 tests (7 of them new). I didn't commit anything or touch the fixtures.

- **Source files:** `APIConfiguration.swift`, `APIError.swift`, `Endpoint.swift`, `HTTPClient.swift` and `TMDBClient.swift`. The signatures match your spec.
- **API key:** `APIConfiguration.load` reads `TMDB_API_KEY` from the environment first, then from `Bundle.main`'s Info.plist. It throws `missingAPIKey` if both are empty. No key is hard-coded.
- **Error parsing:** `APIError.httpStatus` carries the `status_message` from TMDB's error body. For a 401 that is "Invalid API key: You must be granted a valid key."
- **Tests:** `Tests/TMDBAppTests/NetworkingTests.swift` defines `MockURLProtocol`, so nothing touches the real network. It covers:
  - Decoding a successful response.
  - The 401 case from `error_401`.
  - A decoding failure (the `error_401` fixture served as a 200 response and decoded as a movie list).
  - A transport failure.
  - Query items and paths for each endpoint.
  - Key loading.

I also made `APIError` conform to `LocalizedError`, and `TMDBClient` is `@unchecked Sendable`, a Swift concurrency opt-out, because it holds a `URLSession`.

I didn't add any SwiftUI code, so no `#if os(iOS)` wrappers were needed.