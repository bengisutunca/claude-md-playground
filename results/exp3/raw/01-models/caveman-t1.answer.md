I added the domain models in `Sources/TMDBApp/Models/`. `swift build` succeeds and `swift test` passes all 8 tests, including the new decoding tests. Nothing is committed and the fixtures are untouched.

- **Models:** `Movie`, `MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits` and `PagedResponse<T>` are in place. The structs are `Identifiable`, `Hashable` and `Sendable`, except `PagedResponse`, which is not `Identifiable`. `PagedResponse` is `Sendable`, `Equatable` and `Hashable` only when `T` is.
- **Decoder:** `JSONDecoder.tmdb` lives in `TMDBDecoding.swift` and uses snake_case conversion. A missing, null or `""` release date decodes as `nil`, and a malformed date throws.
- **Helpers:** `Movie.year` and `MovieDetail.year` come from the release date in UTC, so the result doesn't depend on the device time zone. `Movie.ratingText` gives one decimal.
- **Tests:** `ModelDecodingTests.swift` decodes the four requested fixtures. It covers the null poster and backdrop paths, the empty release date on "Parasite", and one-decimal rating text.

- **`genre_ids` mapping:** snake_case conversion turns `genre_ids` into `genreIds`, so `Movie` maps `genreIDs` to that key explicitly.
- **Extra fields:** I made `runtime` and `tagline` on `MovieDetail` optional, since TMDB can send null for them. I also gave `CrewMember` a `profilePath`, because the fixture includes one.