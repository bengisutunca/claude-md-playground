The service layer is in place. `swift build` succeeds, and `swift test` passes all 27 tests across 6 suites. Nothing is committed, and I didn't touch the fixtures.

**Source files** (in `Sources/TMDBApp/Services/`):
- **`MovieService`**: the protocol with the four `async throws` methods.
- **`TMDBMovieService`**: implements it on `HTTPClient`, with `client` defaulting to `TMDBClient()`.
- **`ImageURLBuilder`**: nested `Size` enum and `url(path:size:)`. It returns nil for a nil or empty path, and `/inception.jpg` at `.w342` gives `https://image.tmdb.org/t/p/w342/inception.jpg`.
- I deleted the `.gitkeep` that was holding the `Services/` folder open.

**Test files** (in `Tests/TMDBAppTests/`):
- **`MockMovieService`**:
  - It returns fixture data and records every call in `calls`.
  - Setting `error` makes every method throw instead.
  - `popular` picks `popular_page2` for page 2 and `popular_page1` otherwise.
  - `search` picks `search_inception` when the query contains "inception" and `search_empty` otherwise.
- **`TMDBMovieServiceTests`**:
  - A private mock `HTTPClient` checks that each method sends the right `Endpoint` and decodes its fixture.
  - A fifth test checks that client errors propagate.
  - It also has two small tests for `MockMovieService` itself.
- **`ImageURLBuilderTests`**: covers all four sizes, nil and empty paths, and a custom base URL.

I didn't add any iOS-only SwiftUI code, so no `#if os(iOS)` wrapping was needed.