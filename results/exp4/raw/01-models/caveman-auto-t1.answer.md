The domain models are in `Sources/TMDBApp/Models/` and decode all four fixtures. `swift build` succeeds and `swift test` passes all 9 tests (7 new, 2 existing smoke tests). Nothing is committed and the fixtures are unchanged.

**Files added:**
- `JSONDecoder+TMDB.swift`:
  - `JSONDecoder.tmdb` returns a new decoder that converts snake_case keys. It builds a new one on each call because a decoder can be changed after creation, so one shared instance wouldn't be safe across threads.
  - A single date helper that `Movie` and `MovieDetail` both use. It turns a missing value, `null` or `""` into `nil`, reads `yyyy-MM-dd` in UTC, and rejects any other format.
- `Movie.swift`: `year` comes from the UTC date. `ratingText` uses `"%.1f"`, so it gives `"8.4"` whatever the device's language settings. The decoding code sits in an extension so the plain initializer still exists for tests and previews.
- `MovieDetail.swift`: also has overview, image paths and vote fields from the TMDB detail response. `runtime` and `tagline` are optional because TMDB can send `null` for them.
- `Genre.swift` and `Credits.swift` (which also holds `CastMember` and `CrewMember`).
- `PagedResponse.swift`: generic over any `T: Decodable`. It is also `Sendable`/`Hashable` whenever `T` is.

All models are `public`, `Identifiable`, `Hashable` and `Sendable`, and use the exact names you listed.

**Tests** (`Tests/TMDBAppTests/ModelDecodingTests.swift`) cover:
- page fields and every field of one movie in `popular_page1`
- null backdrop (Shawshank) and null poster (Fight Club)
- empty release date in `popular_page2` (Parasite) giving `nil` for both the date and the year
- the detail fixture (genres, runtime, tagline, status, year)
- the credits fixture, including Elliot Page's null profile path
- two small inline checks: a badly formatted date fails to decode, and `ratingText` shows `8` as `"8.0"`

**Worth knowing:**
- A crew member's `id` is the person's ID. The same person can appear several times with different jobs, so a list keyed on `id` alone could have duplicate IDs. A comment in `Credits.swift` notes this.
- I couldn't delete the empty placeholder `Sources/TMDBApp/Models/.gitkeep` because that command was blocked. It's harmless and you can remove it whenever you like.