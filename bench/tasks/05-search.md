Add movie search.
- `SearchViewModel` (`@Observable`, `@MainActor`) with a `query` property. Debounce input by 300 ms by cancelling the previous search `Task`. Queries shorter than 2 characters (after trimming) clear results without calling the service. Use the shared `ViewState`; an empty result is `.empty`.
- Make the debounce delay injectable so tests run without real waiting.
- `SearchView` with `.searchable`, showing results with `MovieRowView`, plus empty and error states.
Add tests: short query does not call the service, rapid typing triggers only one search, `search_inception` result, `search_empty` gives `.empty`, error state.


Constraints:
- Follow the existing MVVM folder layout under `Sources/TMDBApp/`.
- The package must build on macOS with `swift build`; wrap iOS-only SwiftUI modifiers in `#if os(iOS)`.
- Tests use Swift Testing (`import Testing`) and the JSON files in `Tests/TMDBAppTests/Fixtures/` via `Fixture.data(_:)`. Tests must never hit the real network.
- Do not commit; do not modify files under `Tests/TMDBAppTests/Fixtures/`.
- When done, run `swift build` and `swift test`. All tests must pass.
