I've added the domain models and their tests. `swift build` succeeds and `swift test` passes all 9 tests: 7 new ones and the 2 existing smoke tests. Nothing is committed. I only read the fixture files and never wrote to them. I couldn't confirm with `git status` because the command needed approval.

**New files in `Sources/TMDBApp/Models/`:**
- **`JSONDecoder+TMDB.swift`**: `JSONDecoder.tmdb` is a static property that returns a new decoder with snake_case conversion each time, so callers never share one decoder. This file also holds the date rules. TMDB sends `""` for an unknown date, and a decoder's date setting can't turn that into `nil`. So models use one shared helper instead: an empty string, `null` or a missing date gives `nil`, a `yyyy-MM-dd` date is parsed, and anything else is an error.
- **`Movie.swift`**: includes `year` and `ratingText` (always one decimal with a dot, e.g. "8.4", whatever the device language). TMDB's `genre_ids` comes out as `genreIds` under snake_case conversion, so it's mapped to `genreIDs` explicitly.
- **`MovieDetail.swift`**: has all of Movie's fields except `genreIDs` (the detail response sends `genres` instead), plus `runtime`, `tagline`, `genres` and `status`. `runtime` and `tagline` are optional because TMDB can send `null` for them.
- **`Genre.swift`, `Credits.swift`** (`Credits`, `CastMember`, `CrewMember`) and **`PagedResponse.swift`**. `PagedResponse` is `Sendable`, `Equatable` and `Hashable` only when its element type is.

All models are `Identifiable`, `Hashable` and `Sendable`. Dates are read and written in UTC, so a movie released on January 1 never shows the previous year in a time zone behind UTC. I removed the now-unneeded `Models/.gitkeep`.

**Tests** are in `Tests/TMDBAppTests/ModelDecodingTests.swift`. They decode all four fixtures and check:
- the poster and backdrop paths that are null (Fight Club, Shawshank);
- Parasite's empty release date, which gives `nil` for both the date and the year;
- every field of the detail and credits responses;
- that a badly formatted date fails to decode;
- how `ratingText` rounds.

The malformed-date test uses a small JSON string written in the test. Nothing touches the network.

**Watch out for this later:** `CrewMember.id` is the person's TMDB ID, as your spec asked. Real TMDB credits list the same person once per job (for example, Nolan as both Director and Writer). A SwiftUI `ForEach` over `crew` would then see duplicate IDs. The fixtures don't include TMDB's per-credit `credit_id`, which would be a unique ID, so the crew list screen will need to handle this.