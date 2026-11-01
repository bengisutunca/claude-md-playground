Add the domain models in `Sources/TMDBApp/Models/`:
- `Movie` (id, title, overview, posterPath, backdropPath, releaseDate, voteAverage, voteCount, genreIDs). `releaseDate` is an optional `Date`; TMDB sends `"yyyy-MM-dd"` or an empty string, and an empty string must decode as `nil`.
- `MovieDetail` (adds runtime, tagline, genres, status).
- `Genre`, `CastMember`, `CrewMember`, `Credits`.
- Generic `PagedResponse<T: Decodable>` (page, results, totalPages, totalResults).
- A shared `JSONDecoder` factory (`JSONDecoder.tmdb`) using snake_case conversion.
- Computed helpers: `Movie.year: String?` and `Movie.ratingText` (one decimal, e.g. "8.4").
Make models `Identifiable`, `Hashable`, `Sendable`.
Add tests that decode `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205`, covering null image paths and the empty release date.


Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
