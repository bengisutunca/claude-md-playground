The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds with no warnings, and `swift test` passes all 22 tests in 5 suites (the 14 new ones plus the existing ones). Nothing is committed.

**What I added**
- **`APIConfiguration.swift`**: `load(environment:bundle:)` uses `TMDB_API_KEY` from the environment first, then from the Info.plist. A value that is empty or only spaces counts as missing. If neither source has a key, it throws `APIError.missingAPIKey`.
- **`Endpoint.swift`**: the four cases and their paths. `urlRequest(configuration:)` builds a GET request with `api_key`, `language=en-US`, and `page`/`query` where they apply. It also throws `missingAPIKey` if the configuration you pass has an empty key.
- **`APIError.swift`**: the five cases you specified, plus a small type for reading TMDB's error body.
- **`HTTPClient.swift`**: the `HTTPClient` protocol and `TMDBClient`.
  - Network failures become `transport`.
  - A response that isn't HTTP becomes `invalidResponse`.
  - A non-2xx status becomes `httpStatus(code:message:)`, with `message` taken from `status_message`.
  - A bad body becomes `decoding`.
  - With a nil configuration, it calls `APIConfiguration.load()` on every request.

**Tests** (`Tests/TMDBAppTests/MockURLProtocol.swift`, `Tests/TMDBAppTests/NetworkingTests.swift`)
- **Endpoints:** the path and query items for each endpoint, a custom base URL, and the empty-key error.
- **Configuration:** the environment key is used first, the Info.plist is used when it's missing, and loading fails when neither has a key. These tests use a temporary bundle with its own Info.plist.
- **Client:** decoding `popular_page1`, checking the request that was actually sent, the 401 from `error_401` with its message, a decoding failure, and a network failure (one more than you asked for).

All client requests go through `MockURLProtocol`, so no test touches the real network.

**One limitation:** the mock uses a single shared handler, so the "TMDBClient" suite runs its tests one at a time (`.serialized`). Any future suite that uses `MockURLProtocol` will need `.serialized` too, or its tests may interfere with each other.