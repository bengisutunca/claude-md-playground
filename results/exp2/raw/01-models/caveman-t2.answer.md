Models added. `swift build` succeeds and `swift test` passes all 8 tests (6 new, 2 existing smoke tests). Nothing committed, and I didn't touch the fixtures.

**In `Sources/TMDBApp/Models/`:**
- `Movie.swift`
- `MovieDetail.swift`
- `Genre.swift`
- `Credits.swift`, which holds `CastMember`, `CrewMember` and `Credits`
- `PagedResponse.swift`
- `JSONDecoder+TMDB.swift`, which holds `JSONDecoder.tmdb` and the `TMDBDate` parser

**Tests:** `Tests/TMDBAppTests/ModelTests.swift` decodes the four fixtures. It covers the null `poster_path` and `backdrop_path` in `popular_page1`, and the empty `release_date` in `popular_page2`. It also checks `ratingText`.

**Behavior to know:**
- `Movie` and `MovieDetail` have a custom `init(from:)` that turns an empty or malformed `release_date` into `nil`. Because of this, `JSONDecoder.tmdb` only does snake_case conversion and has no date strategy.
- Dates parse as GMT, and `year` is computed in GMT, so a date doesn't shift with the machine's time zone.
- Fields TMDB may omit (`overview`, `voteAverage`, `voteCount`, `genreIDs`, `genres`, `status`) fall back to empty or zero values instead of failing the decode.
- `PagedResponse` is `Sendable`, `Equatable` and `Hashable` only when `T` is.

I also deleted `Sources/TMDBApp/Models/.gitkeep`, since the folder now has files.