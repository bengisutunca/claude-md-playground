The networking layer is in `Sources/TMDBApp/Networking/`. `swift build` succeeds and `swift test` passes all 17 tests, including the new ones. Nothing is committed, and the fixtures are untouched.

- **`APIConfiguration`**: `load()` reads `TMDB_API_KEY` from the environment first, then from `Bundle.main` Info.plist. It trims whitespace and throws `APIError.missingAPIKey` if neither source has a non-empty key. No key is hard-coded.
- **`Endpoint`**: the four cases build a `URLRequest` with `api_key` and `language=en-US`. `page` and `query` are added where they apply.
- **`APIError`**: has exactly the five cases you listed. A non-2xx response puts the TMDB `status_message` into `httpStatus`.
- **`HTTPClient` / `TMDBClient`**: `TMDBClient` runs on an injected `URLSession`. With a nil configuration it calls `APIConfiguration.load()` on each request.

The tests are in `Tests/TMDBAppTests/NetworkingTests.swift`, with `MockURLProtocol` alongside. They cover the following:
- query items for each endpoint
- successful decoding
- the 401 body from `error_401`
- a decoding failure
- a transport error
- configuration loading

No test touches the real network, and the suite is serialized because the mock's handler is shared.

I added a few things you didn't ask for. `APIError` conforms to `LocalizedError`, requests send an `Accept: application/json` header, and there are the transport-error and configuration-loading tests.

My first attempt to write the files with shell heredocs was blocked by a safety check on the command. I wrote them with the file tool instead, so there is no difference in the result.