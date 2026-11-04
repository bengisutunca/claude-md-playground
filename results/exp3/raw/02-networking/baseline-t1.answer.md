The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 16 tests, with no real network calls. Nothing is committed.

- **`APIConfiguration`**: reads `TMDB_API_KEY` from the environment first, then from the `Bundle.main` Info.plist. It throws `APIError.missingAPIKey` when both are missing or empty. No key is hard-coded.
- **`Endpoint`**: builds the four requests with the paths you listed. Every request carries `api_key` and `language=en-US`, plus `page` and `query` where they apply.
- **`APIError`**: has exactly your five cases. On a non-2xx response, `TMDBClient` reads `status_message` from the error body into `httpStatus`.
- **`HTTPClient` and `TMDBClient`**: `TMDBClient` implements `HTTPClient` on an injected `URLSession`. With a nil configuration it calls `APIConfiguration.load()` on each request.

**Tests:** `MockURLProtocol` and `NetworkingTests` cover:
- successful decoding of `popular_page1`;
- the 401 case from `error_401`, checking both the status code and the message;
- a decoding failure;
- query items and paths for each endpoint;
- the configuration loader.

**Additions beyond the spec:**
- `APIError` also conforms to `LocalizedError`.
- `TMDBClient` is marked `@unchecked Sendable`, because it holds a `URLSession`.
- Requests send an `Accept: application/json` header.

I didn't need any iOS-only modifiers, and the fixtures are untouched.