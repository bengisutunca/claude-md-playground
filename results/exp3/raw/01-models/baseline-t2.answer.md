I added the domain models in `Sources/TMDBApp/Models/`. `swift build` succeeds and `swift test` passes all 8 tests (6 new, 2 existing smoke tests). I didn't commit anything or touch the fixtures.

- **Files:** `Movie`, `MovieDetail`, `Genre`, `Credits` (which also holds `CastMember` and `CrewMember`), `PagedResponse<T>`, and `JSONDecoder.tmdb`. I removed the `.gitkeep` from the `Models` folder.
- **Dates:** the models parse `releaseDate` themselves rather than through a decoder date strategy, because an empty string has to become `nil`. An empty or malformed date gives `nil`. `year` is computed in UTC so it doesn't shift with the machine's time zone.
- **Optionals:** `MovieDetail.runtime` and `tagline` are optional. `CastMember.character` and `order` are optional too. `Movie` and `MovieDetail` default missing `overview`, `voteAverage` and similar fields instead of failing to decode.
- **Sendable:** the `Sendable` and `Equatable`/`Hashable` conformances on `PagedResponse<T>` apply only when `T` has them, so `T` is only constrained to `Decodable`.
- **Tests:** `Tests/TMDBAppTests/ModelDecodingTests.swift` decodes `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205`. It covers null poster and backdrop paths, the empty release date on Parasite, and `ratingText` rounding. All tests read fixtures only, with no network.

I also added `ratingText` to `MovieDetail`, which you didn't ask for.