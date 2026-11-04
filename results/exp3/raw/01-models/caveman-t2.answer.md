The domain models are in `Sources/TMDBApp/Models/`. `swift build` succeeds and `swift test` passes all 7 tests (5 new, 2 existing). Nothing is committed, and the fixtures are untouched.

- **Types:** `Movie`, `MovieDetail`, `Genre`, `Credits`, `CastMember`, `CrewMember` and `PagedResponse<T: Decodable>`. All have the names and members you specified, and all are `Identifiable`, `Hashable` and `Sendable`. `PagedResponse` gets `Hashable` and `Sendable` only when `T` does.
- **Decoder:** `JSONDecoder.tmdb` is a static property that returns a fresh snake_case decoder each time it's read.
- **Release date:** an empty string, a missing key or an unparseable value all decode to `nil`. The date is parsed as UTC, so `year` doesn't shift with the local time zone. This lives in `TMDBDecoding.swift` and is shared by `Movie` and `MovieDetail`.
- **Computed helpers:** `Movie.year` and `MovieDetail.year` are four-digit strings, and `ratingText` is one decimal (8.4 for Inception).
- **Tests:** `ModelDecodingTests.swift` decodes the four fixtures you named. It covers the null poster and backdrop paths in `popular_page1`, the empty release date in `popular_page2` (Parasite), and the null `profile_path` in the credits.

I made a few choices you didn't specify:
- `MovieDetail` also carries `overview`, `posterPath`, `backdropPath`, `voteAverage` and `voteCount`, and has its own `ratingText`.
- `CrewMember` also has `profilePath`.
- I deleted `Models/.gitkeep`, since the folder now has files.