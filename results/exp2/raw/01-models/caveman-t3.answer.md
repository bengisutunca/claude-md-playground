Models added in `Sources/TMDBApp/Models/`. `swift build` succeeds and `swift test` passes all 10 tests, including the smoke tests. I removed the now-redundant `Models/.gitkeep` after those runs and didn't rebuild afterward. Nothing is committed, and the fixtures are untouched.

- **Files:** `Movie`, `MovieDetail`, `Genre`, `Credits` (which also holds `CastMember` and `CrewMember`), `PagedResponse` and `JSONDecoder.tmdb`. All models are `Identifiable`, `Hashable` and `Sendable`. They are `Decodable` only, not `Codable`.
- **Empty release date:** `release_date` of `""` (or missing) decodes as `nil`. A malformed date such as `"nope"` throws a `DecodingError`.
- **Dates and `year`:** Dates parse as UTC. `Movie.year` and `MovieDetail.year` read the year in UTC too.
- **Extras:** I added `ratingText` to `MovieDetail`. `Movie` also has a memberwise `init` with defaults, which the rating test uses.
- **Tests:** `Tests/TMDBAppTests/ModelDecodingTests.swift` decodes `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205`. It covers null poster, backdrop and profile paths, the empty release date, the one-decimal `ratingText` and the malformed-date error.