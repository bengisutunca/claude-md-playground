The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 16 tests, including the new networking ones. I didn't commit anything or touch the fixtures.

- **`APIConfiguration`**: `load()` reads `TMDB_API_KEY` from the environment first, then from the `Bundle.main` Info.plist. It throws `APIError.missingAPIKey` if neither has a non-empty key. No key is hard-coded.
- **`Endpoint`**: `urlRequest(configuration:)` adds `api_key` and `language=en-US` to every request. It also adds `page` and `query` where they apply, on the four paths you specified.
- **`APIError`**: has exactly the five cases you listed. On a non-2xx response, `TMDBClient` puts the body's `status_message` into `httpStatus(code:message:)`.
- **`HTTPClient` / `TMDBClient`**: wraps an injected `URLSession`. With a nil configuration it calls `APIConfiguration.load()` on each request.

I made a few small choices beyond the spec:
- `APIError` also conforms to `LocalizedError`.
- `TMDBClient` is declared `@unchecked Sendable`.
- Requests carry an `Accept: application/json` header.
- I deleted the placeholder `Networking/.gitkeep`.

The tests are in `NetworkingTests.swift`, backed by `MockURLProtocol.swift`, and none of them reach the real network:
- **Query items:** one test per endpoint.
- **Success decoding:** `popular_page1`.
- **401 error:** `error_401`, checking the code and the parsed message.
- **Decoding failure:** serves `movie_credits_27205` where a popular-movies page is expected.
- **Missing key:** the missing-key error, plus a key read from the environment.

I didn't add tests for the Info.plist fallback or for transport errors. I also added no SwiftUI code, so nothing needed `#if os(iOS)`.