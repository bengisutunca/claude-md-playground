The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 15 tests.

- **`APIConfiguration`**: `load()` reads `TMDB_API_KEY` from the environment first, then from the `Bundle.main` Info.plist. It throws `.missingAPIKey` if neither has a non-empty value. No key is hard-coded.
- **`Endpoint`**: builds each request with the `api_key` and `language=en-US` query items. It then adds `page` and `query` where they apply.
- **`APIError`**: has exactly the five cases you listed. `httpStatus` carries the `status_message` parsed from the TMDB error body.
- **`HTTPClient` / `TMDBClient`**: with a nil configuration, `TMDBClient` calls `APIConfiguration.load()` on each request. It maps URLSession failures to `.transport`, non-2xx responses to `.httpStatus`, and decode failures to `.decoding`.

I added `MockURLProtocol` and `NetworkingTests`. They cover:
- success decoding for popular, detail and credits
- the 401 body from `error_401`
- a decoding failure
- a transport failure
- query items and paths for all four endpoints
- config loading

Nothing hits the real network, and I didn't commit or touch the fixtures.

- **`@unchecked Sendable`:** `TMDBClient` is marked `@unchecked Sendable`.
- **`.gitkeep`:** I removed `Networking/.gitkeep`, since the folder now has files.