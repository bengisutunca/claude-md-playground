Networking layer is in. `swift build` succeeds and `swift test` passes all 17 tests, nine of them new.

Under `Sources/TMDBApp/Networking/`:
- **`APIConfiguration.swift`:** `load()` reads the `TMDB_API_KEY` environment variable first, then `Bundle` Info.plist. It throws `.missingAPIKey` if both are empty.
- **`APIError.swift`:** the five cases you specified.
- **`Endpoint.swift`:** builds the request with `api_key` and `language=en-US` first, then `page` and `query` where they apply.
- **`HTTPClient.swift`:** `TMDBClient` maps transport failures, non-2xx statuses and decode failures to `APIError`. For non-2xx it pulls `status_message` out of the TMDB error body.

Under `Tests/TMDBAppTests/`:
- **`MockURLProtocol.swift`:** serves canned responses, so tests never hit the network.
- **`NetworkingTests.swift`:** covers success decoding, the 401 from `error_401`, a decoding failure, and query items for each endpoint. It also checks the key lookup order.

One gap: no test for `TMDBClient` throwing `missingAPIKey` when `configuration` is nil. A real `TMDB_API_KEY` in the environment would make it fail, so I left it out.

I did not commit, and I didn't touch the fixtures.