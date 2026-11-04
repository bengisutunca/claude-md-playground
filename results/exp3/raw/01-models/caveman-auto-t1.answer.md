The domain models and their tests are in place. `swift build` succeeds and `swift test` passes all 9 tests (7 new ones plus the 2 existing smoke tests). Nothing is committed and the fixtures are untouched.

**Files in `Sources/TMDBApp/Models/`**
- `JSONDecoder+TMDB.swift`:
  - `JSONDecoder.tmdb` converts snake_case keys and reads `yyyy-MM-dd` dates as UTC.
  - A shared helper turns a missing, `null` or `""` release date into `nil`. Both `Movie` and `MovieDetail` use it, so that rule lives in one place.
  - A date in any other format makes decoding fail instead of quietly becoming `nil`.
- `Movie.swift`: includes `year` (from the UTC date, e.g. "2010") and `ratingText` (one decimal, e.g. "8.4").
- `MovieDetail.swift`: has the same fields as `Movie` except `genreIDs`, plus `runtime`, `tagline`, `genres` and `status`. `runtime` and `tagline` are optional because TMDB can send `null` for them.
- `Genre.swift` and `Credits.swift` (which holds `Credits`, `CastMember` and `CrewMember`). `CrewMember` also has `profilePath`, because the credits fixture includes it.
- `PagedResponse.swift`: generic over `T: Decodable`. It is `Sendable` and `Hashable` only when `T` is.

All of the requested names and signatures are there exactly as specified. Every model is public, `Identifiable`, `Hashable` and `Sendable`. `Movie` and `MovieDetail` keep their memberwise initializers, so test data and previews can be built in code without JSON.

**Tests** (`Tests/TMDBAppTests/ModelDecodingTests.swift`) decode all four fixtures from disk, with no network access. They cover:
- Shawshank's `null` backdrop and Fight Club's `null` poster.
- Elliot Page's `null` profile photo in the credits.
- Parasite's empty release date, which decodes as `nil` and gives `year == nil`.
- A malformed date, which makes decoding throw.
- Rating rounding to one decimal.

**Limitation:** `CastMember` and `CrewMember` use TMDB's person ID as `id`, as the required API specifies. In real data the same person can appear more than once, for example a crew member credited for two jobs. A SwiftUI list keyed on `id` would then see duplicate IDs. The fixtures don't have this case. If it matters later, TMDB's per-credit `credit_id` would be a unique key.