The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 17 tests.

- **`APIConfiguration`**:
  - It reads `TMDB_API_KEY` from the environment first, then from the `Bundle.main` Info.plist.
  - It trims whitespace, so a blank key counts as missing.
  - If neither source has a key, it throws `APIError.missingAPIKey`.
- **`Endpoint`**: it builds the four paths with `api_key` and `language=en-US` query items. `page` and `query` are added where they apply.
- **`APIError`**: the five cases match your list. For a non-2xx response, `status_message` from the TMDB error body goes into `httpStatus`.
- **`HTTPClient` and `TMDBClient`**:
  - A `CancellationError` passes through unchanged. Any other `URLSession` failure becomes `.transport`.
  - Decoding failures become `.decoding`. Only 2xx responses are decoded.
  - With a nil configuration it calls `APIConfiguration.load()` on each request.

The new types are `internal`, like the existing models, so they aren't visible outside the module.

The tests are in `NetworkingTests.swift`, which uses `MockURLProtocol.swift` to serve fixtures, so nothing touches the network. They cover:
- a successful decode of `popular_page1`;
- the 401 case from `error_401`, including its message;
- a decoding failure, by serving `error_401` as a 200 response;
- a transport failure;
- query items and paths for each endpoint;
- `APIConfiguration.load`, including the missing-key error.

I removed `Networking/.gitkeep`. Nothing is committed, and I didn't touch the fixtures.