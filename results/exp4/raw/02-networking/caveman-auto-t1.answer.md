I've added the networking layer in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 22 tests in 5 suites, including the existing model and smoke tests. Nothing is committed.

**Source files** (all internal, like the existing Models):
- **`APIConfiguration.swift`**: `load(environment:bundle:)` uses the `TMDB_API_KEY` environment variable first, then the Info.plist key. A value that is empty or only whitespace counts as missing, so an empty environment variable falls back to the plist. If neither has a key it throws `APIError.missingAPIKey`.
- **`Endpoint.swift`**: builds each path on top of `baseURL` and always adds `api_key` and `language=en-US`. `page` and `query` are added where they apply. It also throws `missingAPIKey` if the configuration's key is empty.
- **`APIError.swift`**: the five cases exactly as specified, plus a small type for reading the TMDB error body.
- **`HTTPClient.swift`**: the `HTTPClient` protocol and `TMDBClient`. Session failures become `transport`, a response that isn't HTTP becomes `invalidResponse`, a status outside 2xx becomes `httpStatus` with the parsed `status_message` (nil if the body can't be parsed), and JSON errors become `decoding`. With a nil configuration it calls `APIConfiguration.load()` on every request.
- I deleted `Networking/.gitkeep` because the folder now has files.

**Tests:**
- **`MockURLProtocol.swift`**: each mock session has its own handler, so Swift Testing can run the tests in parallel without them interfering. No test touches the real network.
- **`NetworkingTests.swift`** covers:
  - **Endpoints:** path and query items for all four, a custom `baseURL`, `Equatable`, and that a `&` in a search query is percent-encoded.
  - **Configuration:** the environment key, the plist fallback (using a temporary bundle with its own Info.plist), environment taking priority, and the missing/blank-key error.
  - **Client:** a successful decode, the 401 from `error_401` giving `httpStatus(401, "Invalid API key: …")`, a decoding failure (the credits fixture decoded as a movie list), and a transport error.

There is no test for `TMDBClient` with a nil configuration. That path reads the real process environment, so the result would change on a machine where `TMDB_API_KEY` is set.

`git status` needed your approval and didn't run, so I couldn't print the final list of changed files. The changes are the four new source files, the two new test files, and the deleted `.gitkeep`.