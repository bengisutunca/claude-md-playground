I've added the networking layer to `Sources/TMDBApp/Networking/` along with its tests. `swift build` is clean with no warnings, and `swift test` passes all 27 tests in 5 suites (the 12 that were already there plus 15 new ones). Nothing is committed.

**Source files**
- **`APIConfiguration.swift`**: `load(environment:bundle:)` checks the `TMDB_API_KEY` environment variable first, then the Info.plist. Values are trimmed, so a blank or whitespace-only value counts as missing. If neither source has a key, it throws `APIError.missingAPIKey`.
- **`Endpoint.swift`**: builds a GET request with the four paths and the `api_key`, `language=en-US`, `page` and `query` query items. I encode query values myself rather than leaving it to `URLComponents.queryItems`, because that leaves `+` alone and TMDB would read a search for "C++" as "C  ". It also throws `missingAPIKey` if a configuration was passed in with an empty key.
- **`APIError.swift`**: the five cases exactly as specified, plus readable error messages for later UI use. For a 401 from `error_401`, the message is TMDB's `status_message`.
- **`HTTPClient.swift` / `TMDBClient.swift`**: the protocol and its implementation on an injected `URLSession`. With a nil configuration it calls `APIConfiguration.load()` on every request, so a key added later is picked up without rebuilding the client.

**Decisions you may want to check**
- **Access level:** the new types are internal, the same as the existing models.
- **`HTTPClient` is `Sendable`:** this makes it easier to call from `@MainActor` view models later. The catch is that any future mock client with mutable state will need to be an actor or use a lock.
- **Extra initializer:** I added `TMDBClient(session:configurationProvider:)`. The required nil-configuration path runs through it, and tests use it to check that the configuration is loaded on each request.
- **Bad URL:** since the error cases are fixed, a URL that can't be built is reported as `.transport(URLError(.badURL))`.
- **`.gitkeep`:** I removed `Networking/.gitkeep`, since the folder now has real files.

**Tests**
- **`MockURLProtocol`**: Swift Testing runs tests in parallel, so a single shared handler would let tests overwrite each other's responses. Instead, each mock session gets its own handler. Every request goes through the mock, so nothing reaches the real network.
- **Coverage**: everything you listed (decoding success for all four endpoints, the 401, a decoding failure, and query items for each endpoint), plus a few extras. These include special-character encoding, environment-over-plist priority and fallback, a non-JSON error body, a network failure, a non-HTTP response, and loading the key on each request.
- **One test depends on your machine:** the test for `TMDBClient(session:)` with no configuration gives a different result depending on whether `TMDB_API_KEY` is set. It passes either way and stays on the mock session. Here it took the "no key" path.

While checking for warnings I cleared some build folders and then ran `swift package clean`. That only deleted build artifacts in `.build/`, which have since been rebuilt.