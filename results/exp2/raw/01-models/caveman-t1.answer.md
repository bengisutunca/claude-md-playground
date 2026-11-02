Models done. `swift build` and `swift test` pass (8 tests). Nothing committed. Fixtures untouched.

Added in `Sources/TMDBApp/Models/`:
- `Movie.swift`, `MovieDetail.swift`, `Genre.swift`, `Credits.swift` (`CastMember`, `CrewMember`, `Credits`), `PagedResponse.swift`
- `JSONDecoder+TMDB.swift`: `JSONDecoder.tmdb` with snake_case conversion, plus a `TMDBDate` helper that parses `yyyy-MM-dd` in UTC.

Design notes:
- Empty or malformed `release_date` decodes as `nil`.
- `Movie.genreIDs` uses the coding key `"genreIds"`, since the decoder converts `genre_ids` to that.
- `PagedResponse<T: Decodable>` is `Hashable` and `Sendable` only when `T` is. That keeps the required `Decodable`-only constraint.
- I added `ratingText` and a `Movie` memberwise `init` with defaults, plus `ratingText` on `MovieDetail`. These are extras beyond the spec.

Tests are in `Tests/TMDBAppTests/ModelDecodingTests.swift`. They cover all four fixtures, null `poster_path`, `backdrop_path` and `profile_path`, the empty release date, and `ratingText` rounding.