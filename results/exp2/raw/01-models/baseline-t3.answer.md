I added the domain models and their tests. `swift build` succeeds, and `swift test` passes all 7 tests (2 existing smoke tests plus 5 new ones).

The model code is in `Sources/TMDBApp/Models/`:
- **Models:** `Movie`, `MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits` and a generic `PagedResponse<T>`. All are `Identifiable`, `Hashable` and `Sendable`, except `PagedResponse`, which has no `id` and gets those conformances only when `T` does. `Movie.year` and `Movie.ratingText` are in `Movie.swift`. `MovieDetail` also has `year` and `ratingText`.
- **Decoder:** `JSONDecoder.tmdb` uses snake_case conversion. It's a computed static property, so each access returns a fresh decoder.
- **Dates:** `JSONDecoder.tmdb` doesn't decode dates itself. `Movie` and `MovieDetail` parse `release_date` themselves (UTC, `yyyy-MM-dd`). An empty or malformed string becomes `nil`, so `year` is `nil` too.
- **`genreIDs`:** the snake_case conversion turns `genre_ids` into `genreIds`, so `genreIDs` has a custom coding key.

The tests are in `Tests/TMDBAppTests/ModelDecodingTests.swift`. They load `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205` through `Fixture.data(_:)`, so nothing touches the network. They cover null poster, backdrop and profile paths, the empty release date, and one-decimal rating text.

I didn't commit anything or touch the fixture files.