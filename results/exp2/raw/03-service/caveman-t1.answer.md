Service layer added, and the build and tests pass: `swift build` is clean, and `swift test` ran 28 tests in 5 suites, all passing. Nothing is committed, and `Fixtures/` is untouched.

- **`MovieService` and `TMDBMovieService`:** the protocol and the `HTTPClient`-backed implementation use the exact names and signatures you gave. Both are in `Sources/TMDBApp/Services/`.
- **`ImageURLBuilder`:** a nil, empty, or `"/"`-only path returns `nil`. A path without a leading slash also works.
- **`MockMovieService`:** it returns fixture data, or throws `error` when you set one, and records every call in `calls`.
- **Tests:** `MovieServiceTests` covers each service method with a mock `HTTPClient` and checks that errors propagate. It also exercises `MockMovieService`. `ImageURLBuilderTests` covers all four sizes, nil/empty paths, and a custom base URL. Nothing touches the network.

I also deleted `Sources/TMDBApp/Services/.gitkeep` since the folder now has real files.