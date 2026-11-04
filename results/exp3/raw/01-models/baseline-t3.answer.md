The domain models and their tests are in. `swift build` succeeds, and `swift test` passes all 7 tests (5 new, 2 existing smoke tests). Nothing is committed, and the fixtures are untouched.

**Models** (`Sources/TMDBApp/Models/`):
- `Movie`, `MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits` and `PagedResponse<T>` all follow your API. They are `Identifiable`, `Hashable`, `Sendable` and `Decodable`. `PagedResponse` is `Sendable`, `Equatable` and `Hashable` when `T` is.
- `JSONDecoder.tmdb` is a static property that returns a fresh decoder with snake_case key conversion each time. A fresh one avoids sharing a non-`Sendable` decoder across threads.
- `releaseDate` is parsed in UTC. An empty string (or one that isn't `yyyy-MM-dd`) becomes `nil`. `year` is derived from that date, so it is `nil` too.
- `ratingText` formats `voteAverage` to one decimal, so 8.4 gives "8.4" and 7 gives "7.0".
- `MovieDetail` also has `year` and `ratingText`.
- Beyond what you asked for, `Movie` has a memberwise `init` for use in tests and previews. `MovieDetail` has no such `init`.
- I made `tagline`, `CastMember.character` and `CastMember.order` optional, since TMDB can omit them.

**Tests** (`Tests/TMDBAppTests/ModelDecodingTests.swift`) cover `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205`. They check null poster and backdrop paths, the empty release date decoding to `nil`, and a null cast `profilePath`.

I also removed `Models/.gitkeep`.