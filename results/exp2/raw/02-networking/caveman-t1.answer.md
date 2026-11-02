Networking layer done. `swift build` passes. `swift test` passes all 18 tests, and none hit the real network.

Added in `Sources/TMDBApp/Networking/`:
- `APIConfiguration.swift`
- `APIError.swift`
- `Endpoint.swift`
- `HTTPClient.swift` (the `HTTPClient` protocol and `TMDBClient`)

Added in `Tests/TMDBAppTests/`:
- `MockURLProtocol.swift`
- `NetworkingTests.swift`

Behavior you might not assume:
- **Key lookup:** `APIConfiguration.load` trims whitespace from the key. It falls through to Info.plist when the environment value is empty.
- **Empty key:** `Endpoint.urlRequest` throws `missingAPIKey` for an empty `apiKey`.
- **Error body:** non-2xx responses read `status_message` from the body. A body that doesn't parse gives `message: nil`.
- **`Sendable`:** `TMDBClient` is `@unchecked Sendable`.
- **Test suite:** `NetworkingTests` is `.serialized`, because the mock handler is shared static state.

Besides the four required cases, I added tests for a transport error, an empty API key and `APIConfiguration.load`. I removed `Networking/.gitkeep`. Nothing is committed, and I didn't touch the fixtures.