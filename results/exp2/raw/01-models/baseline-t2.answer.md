The models and tests are in. `swift build` succeeds and `swift test` passes all 8 tests. I haven't committed anything or touched the fixtures.

**What I added in `Sources/TMDBApp/Models/`**
- **`JSONDecoder+TMDB.swift`:** `JSONDecoder.tmdb` is a static property that uses snake_case key conversion. It returns a fresh decoder on each access.
- **Date parsing:** a `TMDBDate` helper parses `"yyyy-MM-dd"` in UTC. An empty or malformed string decodes as `nil`, so `year` is also `nil`.
- **`Movie`:** all the required fields, plus `year` and `ratingText`. Its `genreIDs` property maps to the JSON key `genre_ids`, which the snake_case conversion turns into `genreIds`.
- **`MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits`:** these have the fields you listed and the same `Identifiable`/`Hashable`/`Sendable` conformances. `MovieDetail` also has `year` and `ratingText`.
- **`PagedResponse<T: Decodable>`:** it is `Sendable`, `Equatable` and `Hashable` whenever `T` is.

**Tests:** `Tests/TMDBAppTests/ModelDecodingTests.swift` decodes the four fixtures you named through `Fixture.data(_:)`, with no network. It covers null poster and backdrop paths, the empty release date on page 2, a null cast profile path, and `ratingText` rounding.

**Defaults I chose**
- Fields that can be null or missing in TMDB responses are optional or default: `runtime` and `tagline` are optional, and `character`, `order` and `profilePath` on cast and crew are optional.
- Missing `overview`, `status`, `genres` and vote fields default to empty or zero.
- `Movie` also has a memberwise `init` with defaults, which the rating test uses.

I didn't need any iOS-only `#if os(iOS)` wrapping, since these are model types only.