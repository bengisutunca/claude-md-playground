Networking layer done. `swift build` succeeds. `swift test` passes: 20 tests, including 11 new ones.

Added in `Sources/TMDBApp/Networking/`:
- `APIConfiguration.swift`
- `APIError.swift`
- `Endpoint.swift`
- `HTTPClient.swift`
- `TMDBClient.swift`

Added in `Tests/TMDBAppTests/`:
- `MockURLProtocol.swift`
- `NetworkingTests.swift`

Tests cover:
- Success decoding.
- The `error_401` message arriving in `httpStatus`.
- A decoding failure.
- A transport failure.
- Query items and paths for each endpoint.
- Environment key loading, and `missingAPIKey` when the key is empty.

- **Serialized suite:** `NetworkingTests` is `.serialized`. `MockURLProtocol.handler` is static, so parallel tests would clobber each other.
- **Unrequested additions:** I also added an `Accept: application/json` header to each request and tests for non-JSON error bodies (`message` is nil) and transport errors. `APIError` also conforms to `LocalizedError`.
- **Info.plist path untested:** I did not test the Info.plist branch of `load`. `Bundle.main` has no `TMDB_API_KEY` under `swift test`.
- **Not committed:** Nothing is committed. Fixtures are untouched. I deleted `Sources/TMDBApp/Networking/.gitkeep`.