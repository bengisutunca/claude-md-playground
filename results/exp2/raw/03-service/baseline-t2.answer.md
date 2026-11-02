The service layer is in. `swift build` succeeds, and `swift test` passes all 30 tests, including the new ones. Nothing is committed, and I didn't touch the fixtures.

**Source files in `Sources/TMDBApp/Services/`**
- `MovieService.swift` has the `MovieService` protocol and `TMDBMovieService`, which sends `.popular`, `.search`, `.movieDetail` and `.credits` through the `HTTPClient`.
- `ImageURLBuilder.swift` builds `baseURL/<size>/<path>`. A nil or empty path returns nil, and so does a path of just `/`. A path without a leading slash also works.
- I removed the placeholder `.gitkeep` from the `Services` folder.

**Test files in `Tests/TMDBAppTests/`**
- `MockMovieService.swift` is the reusable mock. It returns fixture data, or throws `error` if you set it, and records each call in `calls`.
- `MovieServiceTests.swift` tests `TMDBMovieService` against a private mock `HTTPClient`. It checks the endpoint used, the decoded result and error propagation. It also exercises `MockMovieService`.
- `ImageURLBuilderTests.swift` covers all four sizes, nil and empty paths, a missing leading slash, and a custom base URL.

The protocol, `TMDBMovieService` and `ImageURLBuilder` are internal, not `public`, to match the existing networking types. None of the tests touch the real network.