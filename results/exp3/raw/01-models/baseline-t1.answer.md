The domain models and their tests are in. `swift build` succeeds and `swift test` passes all 7 tests (2 existing smoke tests, 5 new). I haven't committed anything or touched the fixtures.

**What I added in `Sources/TMDBApp/Models/`:**
- **Models:** `Movie`, `MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits` and `PagedResponse<T>`, with the property names you listed. All are `Identifiable`, `Hashable` and `Sendable`, except `PagedResponse`, which has no `id` and picks up `Hashable`/`Sendable` only when `T` does.
- **Decoder:** `JSONDecoder.tmdb` is a static property that uses snake_case conversion.
- **Computed helpers:** `Movie.year`, `Movie.ratingText` (one decimal) and `MovieDetail.year`. I also gave `MovieDetail` a `ratingText`, which you didn't ask for.
- **Date handling:** `releaseDate` is parsed inside each model, not by a decoder date strategy, because a strategy can't return `nil` for the empty string. An empty or malformed date becomes `nil`. Dates parse as UTC, so `year` doesn't shift near New Year.
- **Genre IDs:** the snake_case conversion turns `genre_ids` into `genreIds`, so `Movie` maps that key to `genreIDs` explicitly.

**Tests:** `Tests/TMDBAppTests/ModelDecodingTests.swift` decodes `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205`. It checks the null `poster_path` and `backdrop_path` cases in page 1, the empty release date in page 2, and a null `profile_path` in the credits. It reads the fixtures through `Fixture.data(_:)`, so nothing touches the network.

I also added a small internal `TMDBDate` helper, in `JSONDecoder+TMDB.swift`, that does the date parsing and year extraction.