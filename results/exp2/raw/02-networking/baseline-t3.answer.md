The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 18 tests, including the 11 new ones. Nothing is committed, and I didn't touch the fixtures.

- **`APIConfiguration`:** `load()` reads `TMDB_API_KEY` from the environment first, then from the `Bundle.main` Info.plist. It throws `APIError.missingAPIKey` if neither has a non-empty key, and no key is hard-coded.
- **`Endpoint`:** all four cases build their `URLRequest` with `api_key` and `language=en-US`. `page` and `query` are added where they apply.
- **`APIError`:** has exactly the five cases you listed. For a non-2xx response, `TMDBClient` reads `status_message` from the body into `httpStatus`.
- **`HTTPClient` and `TMDBClient`:** the client decodes with the existing snake_case decoder. Session errors become `.transport`, and decode failures become `.decoding`.
- **Tests:** `Tests/TMDBAppTests/NetworkingTests.swift` uses a `MockURLProtocol`, so nothing touches the real network. It covers these cases:
  - **Responses:** success decoding, the 401 from `error_401`, a decoding failure (the credits fixture decoded as a movie list), and a transport error.
  - **Request building:** path and query items for each endpoint.
  - **Configuration:** the environment key, and the missing-key error.

I also removed the `.gitkeep` from `Networking/`. The configuration tests never read the real `Bundle.main` Info.plist.