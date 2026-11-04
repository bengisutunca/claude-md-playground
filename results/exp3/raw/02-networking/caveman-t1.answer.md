The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 14 tests (7 of them new). Nothing is committed, and I didn't touch the fixtures.

- **Files:** `APIConfiguration.swift`, `APIError.swift`, `Endpoint.swift`, and `HTTPClient.swift`, which holds both the `HTTPClient` protocol and `TMDBClient`.
- **Tests:** `Tests/TMDBAppTests/NetworkingTests.swift` has the `MockURLProtocol` and serves fixtures through an ephemeral `URLSession`, so nothing reaches the network. It covers:
  - successful decoding of `popular_page1`;
  - the 401 from `error_401`, with the `status_message` text checked;
  - a decoding failure (the 401 body served as a 200 response and decoded as `PagedResponse<Movie>`);
  - a transport error wrapped as `APIError.transport`;
  - the path and query items for each of the four endpoints;
  - `APIConfiguration.load` with a key set and with an empty key.
- **Access level:** All the new types are internal, like the existing models, and the tests reach them through `@testable import`.
- **Query building:** `Endpoint.urlRequest` puts `api_key` and `language=en-US` first, followed by `page` and `query` where they apply. The result is a GET with an `Accept: application/json` header.
- **Invalid URL case:** If the base URL can't be turned into a valid request URL, it throws `APIError.invalidResponse`, since your case list has no better fit.
- **Tests not run:** The Info.plist fallback in `APIConfiguration.load` isn't exercised, because the test bundle has no `TMDB_API_KEY`. `TMDBClient`'s `configuration: nil` default (load on each request) isn't tested either.

My first attempt to write the files in one shell command was blocked by a safety check. I redid them with the file-writing tool, and that is what the results above come from.