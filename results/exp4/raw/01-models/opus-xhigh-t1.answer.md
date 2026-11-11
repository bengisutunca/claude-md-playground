The models are in `Sources/TMDBApp/Models/` and the tests are in `Tests/TMDBAppTests/ModelTests.swift`. `swift build` succeeds with no warnings and `swift test` passes all 11 tests: 9 new and the 2 existing smoke tests. Nothing is committed and the fixtures are unchanged.

**What was added**
- **Model files:** `Movie`, `MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits` and `PagedResponse<T>`, all using your exact names. Each model is `Identifiable`, `Hashable` and `Sendable`. `PagedResponse` is `Sendable`, `Equatable` and `Hashable` when `T` is.
- **`JSONDecoder+TMDB.swift`:** `JSONDecoder.tmdb` is a computed static property that returns a new decoder each time. A single shared decoder could be changed by one caller and affect everyone else.
- **`TMDBDate.swift`:** the shared date handling. A missing `release_date`, `null` or `""` all become `nil`. Dates are read in UTC, so a date like `2010-01-01` never shows as 2009 on a device in a time zone behind UTC.
- **Tests:** they decode all four fixtures, including the null poster, backdrop and profile paths and Parasite's empty release date. A few small inline JSON snippets cover the edge cases: a missing, null or malformed date, dates on New Year's Day and Eve, and rating rounding. Nothing touches the network.

**Decisions worth checking**
- **A badly formatted date fails decoding.** Something like `"15/07/2010"` throws an error instead of becoming `nil`. That fits TMDB's stated format, but it also means one bad entry fails a whole page. Switching to a silent `nil` is a one-line change in `TMDBDate.swift`.
- **`ratingText` always uses a dot.** This machine's locale is Turkish, where the usual number formatting would give "8,4". I used `String(format: "%.1f")`, which always gives "8.4".
- **Models are decode-only.** The comment in `TMDBApp.swift` calls them "Codable", but they only support decoding. Saving them back to JSON would need custom code to write the date in the same format.
- **Public types:** the types are public with public initializers, matching the existing `public enum TMDBApp`. A library product needs that if an app target is going to build preview or test data.
- **Extras beyond the spec:**
  - `MovieDetail` also has `overview`, `posterPath`, `backdropPath`, `voteAverage`, `voteCount` and `ratingText`.
  - `CrewMember` has `profilePath`, since it's in the fixture.
  - `runtime` and `tagline` are optional because TMDB can send `null` for them.

**For a later step:** `id` on `CastMember` and `CrewMember` is the TMDB person ID, so it isn't unique within a list. One person often has several crew jobs, such as Director and Writer, and `ForEach(credits.crew)` would then get duplicate IDs. The views will need a different ID there; I've noted this in the doc comments on both types.