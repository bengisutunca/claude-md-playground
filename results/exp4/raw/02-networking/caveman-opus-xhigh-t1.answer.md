The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` and `swift test` both pass: 17 tests in 5 suites, with no warnings in either the app or the test target. Nothing is committed, and the fixture files are unchanged.

**What's there**
- **`APIConfiguration`** reads the key from the `TMDB_API_KEY` environment variable first, then from the same key in the bundle's Info.plist. Whitespace is trimmed, so a blank value counts as missing and the next source is tried. If neither has a key it throws `APIError.missingAPIKey`. The key is never hard-coded.
- **`Endpoint`** has the four cases with the paths you specified. Every request gets `api_key` and `language=en-US`, plus `page` and `query` where they apply. A `+` in a search query is escaped as `%2B`, because otherwise TMDB would read it as a space.
- **`APIError`** has exactly the five cases you listed. A helper reads TMDB's `status_message` from an error response; if the body isn't TMDB JSON, the message is `nil`.
- **`HTTPClient` and `TMDBClient`** are in `HTTPClient.swift`. `send` only ever throws `APIError`:
  - network failures become `.transport`
  - non-HTTP responses become `.invalidResponse`
  - non-2xx status codes become `.httpStatus`
  - bad JSON becomes `.decoding`

  With a `nil` configuration, the client loads it again on every request.
- I removed `Networking/.gitkeep`, since the folder now has files (the earlier models step did the same for `Models/`).

**Tests** (`Tests/TMDBAppTests/MockURLProtocol.swift` and `NetworkingTests.swift`)
- `MockURLProtocol` answers each test from its own fake host, so tests can run in parallel and nothing touches the real network.
- Client tests: decoding a successful `popular_page1` response; the 401 from `error_401` giving `httpStatus(code: 401, message: "Invalid API key: …")`; a 500 with a non-JSON body giving a `nil` message; and a decoding failure.
- Endpoint tests: the path and exact query items for all four endpoints, and escaping of special characters in a search query.
- Configuration tests: the environment variable winning, the Info.plist fallback (checked with a temporary bundle), and missing, empty or blank keys throwing `missingAPIKey`.

**Not covered:** calling `TMDBClient` with no configuration in tests, since that depends on the real environment and `Bundle.main` and can't be made reliable. Also, a cancelled request comes back as `.transport(URLError(.cancelled))`, so code that cancels searches will need to check for that.