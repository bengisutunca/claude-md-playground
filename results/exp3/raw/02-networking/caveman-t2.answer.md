The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 17 tests (9 of them new). Nothing is committed, and the fixtures are untouched.

**Source files:** `APIConfiguration.swift`, `APIError.swift`, `Endpoint.swift`, `HTTPClient.swift` and `TMDBClient.swift`. I removed the `.gitkeep` from the folder. All names and signatures match your spec.

**Tests:** `NetworkingTests.swift` and `MockURLProtocol.swift` in `Tests/TMDBAppTests/`. They cover:
- successful decoding
- the 401 case (`status_message` parsed from `error_401`)
- a decoding failure
- a transport failure
- query items and paths for each of the four endpoints
- `APIConfiguration.load` with a key, an empty key and no key

The mock serves all responses through a custom `URLSession`, so nothing touches the real network.

- **Env var vs. Info.plist test:** I only tested the environment-variable path. The Info.plist fallback is untested because it would need a custom `Bundle`.
- **Serialized suite:** the networking suite is marked `.serialized` because `MockURLProtocol` keeps one shared handler.
- **Extras you didn't ask for:**
  - `Endpoint` requests add an `Accept: application/json` header.
  - `APIError` conforms to `LocalizedError`.
  - Whitespace around the API key is trimmed.

I left the SwiftUI side alone, so no `#if os(iOS)` wrapping was needed.