The domain models are in `Sources/TMDBApp/Models/`, and `swift build` and `swift test` both pass (8 tests). I didn't commit anything, and the fixtures are untouched.

- **Models:** `Movie`, `MovieDetail`, `Genre`, `CastMember`, `CrewMember`, `Credits` and `PagedResponse<T>` are all `Identifiable`, `Hashable` and `Sendable` except `PagedResponse`, which isn't `Identifiable`. They have the names and members you listed.
- **`PagedResponse`:** It gets `Sendable`, `Equatable` and `Hashable` only when `T` does.
- **Decoder:** `JSONDecoder.tmdb` uses snake_case conversion. `genreIDs` has an explicit coding key, `genreIds`, because the conversion produces that spelling from `genre_ids`.
- **Release dates:** An empty or malformed string decodes as `nil`; valid dates parse as UTC. `year` is also computed in UTC, so the result doesn't depend on the machine's time zone.
- **Helpers:** `Movie.year` and `Movie.ratingText` are there, and `MovieDetail` has the same two.
- **Optional fields:** Missing optional JSON keys fall back to defaults (empty string, 0, empty array) instead of failing the decode.
- **Tests:** `ModelTests.swift` decodes `popular_page1`, `popular_page2`, `movie_detail_27205` and `movie_credits_27205` through `Fixture.data(_:)`, so nothing touches the network. They cover null poster and backdrop paths, the empty release date on "Parasite", and a null cast `profile_path`.

I did no SwiftUI work here, so there was nothing to wrap in `#if os(iOS)`.