# Plan: genre filter on the Popular tab

I read all the source and test files. Nothing was created, changed or run. I skipped `swift test` because it writes `.build/`.

**Approach in brief:** The view model asks for "popular movies, optionally in genre X". The service picks the endpoint: `/movie/popular` when no genre is selected (same as today), and `/discover/movie?with_genres=…` when one is. The genre list is optional: if loading it fails, the filter is hidden and the movie list still works.

## Models — `Models/Genre.swift`
- Keep `Genre` as it is. It already has the right shape and conformances.
- Add a response wrapper next to it, the same way `PagedResponse` sits in Models:
  ```swift
  struct GenreListResponse: Decodable, Sendable { let genres: [Genre] }
  ```
- `Movie.genreIDs` already exists and is only needed for the preview service's local filtering.

## Networking — `Networking/Endpoint.swift`
- Add two cases:
  - `.movieGenres`: path `/genre/movie/list`. It joins `.movieDetail, .credits` in the `break` branch of `queryItems`, so it sends only `api_key` and `language` (genre names come back in `en-US`).
  - `.discover(genreID: Int, page: Int)`: path `/discover/movie`. It adds `page`, `with_genres` (from `String(genreID)`) and `sort_by=popularity.desc`. TMDB already sorts this way by default; sending it explicitly makes "still sorted by popularity" something a test can check.
- Don't change `.popular(page:)`. A single case whose path depends on a parameter would be harder to follow.
- `HTTPClient` and `TMDBClient` need no changes, since `send` is already generic.

## Service — `MovieService`, `TMDBMovieService`, `PreviewMovieService`
- `MovieService`:
  - Change `popular(page:)` to `popular(page: Int, genreID: Int?)`.
  - Add `func genres() async throws -> [Genre]`.
  - Don't add a convenience overload; there are only a few call sites to update.
- `TMDBMovieService`:
  ```swift
  func popular(page: Int, genreID: Int?) async throws -> PagedResponse<Movie> {
      let endpoint: Endpoint = genreID.map { .discover(genreID: $0, page: page) } ?? .popular(page: page)
      return try await client.send(endpoint, as: PagedResponse<Movie>.self)
  }
  func genres() async throws -> [Genre] {
      try await client.send(.movieGenres, as: GenreListResponse.self).genres
  }
  ```
- `PreviewMovieService`:
  - Give the three sample movies `genreIDs`.
  - Add a static `genres` list.
  - `popular` filters with `genreIDs.contains`, so SwiftUI previews show the filter working.
- `AppDependencies` and `RootView` don't change.

## View model — `ViewModels/MovieListViewModel.swift`
New state:
- `private(set) var genres: [Genre] = []`
- `private(set) var selectedGenreID: Int?`
- `var selectedGenre: Genre? { genres.first { $0.id == selectedGenreID } }`

New methods:
```swift
/// Optional: on failure the filter stays hidden and the list is unaffected; retried on next appear.
func loadGenres() async {
    guard genres.isEmpty, let loaded = try? await service.genres() else { return }
    genres = loaded
}

/// Clears the previous genre's movies (it doesn't keep them visible like refresh does), then reloads page 1.
func selectGenre(_ id: Int?) async {
    guard id != selectedGenreID else { return }
    selectedGenreID = id
    movies = []; currentPage = 0; totalPages = 1
    await refresh()
}
```
- In `fetch`, call `service.popular(page: page, genreID: selectedGenreID)`. Later pages and refreshes then keep the filter.
- **Why clear first:** `refresh()` keeps the old movies on screen. After a genre switch, that would show the previous genre's movies under the new label. If the request then failed, the stale list would stay with only a `paginationError` footer. With `movies` empty, `refresh()` shows `.loading`, and a failure becomes a full `.failed` state.
- Out-of-date responses (a fast switch from Action to Comedy, or a page-2 request for the old genre still in flight) are already discarded by the existing `generation` counter.
- `loadGenres()` is separate from `load()` so the existing tests that check exact `calls` stay predictable.

## View — `Views/MovieListView.swift`
- Add `.task { await viewModel.loadGenres() }` next to the existing `.task { await viewModel.load() }`.
- Add a `.toolbar` with a `Menu` that contains a `Picker`: "All Genres" tagged `Int?.none`, then one entry per genre tagged with its `id`.
  - The binding's setter calls `Task { await viewModel.selectGenre($0) }`, the same way the view already does `Task { await viewModel.refresh() }`.
  - The label is `Label(selectedGenre?.name ?? "All Genres", systemImage: "line.3.horizontal.decrease.circle")`, using the `.fill` icon when a genre is active. That gives VoiceOver a text label and value.
  - The menu only appears when `genres` isn't empty.
- **Placement matters:** attach the toolbar to `content`, outside the `switch`. Then the filter stays reachable in the loading, empty and failed states, so the user is never stuck on a genre with no results.
- `.empty` case: pass a message when filtered, e.g. `"No popular \(name) movies."`.

## Tests
New fixture: `Fixtures/genre_movie_list.json` (e.g. Action 28, Adventure 12, Science Fiction 878). `.copy("Fixtures")` in `Package.swift` picks it up automatically. The discover tests reuse the popular page fixtures and check the recorded calls.

**`MockMovieService`:**
- Change the call case to `case popular(page: Int, genreID: Int? = nil)`. Thanks to the default value, every existing `.popular(page: 1)` assertion still compiles and still means "unfiltered".
- Add a `.genres` call case, plus `genres()`, which decodes the new fixture.
- `popular(page:genreID:)` records the genre and returns the same page fixtures.

| Suite | Test |
|---|---|
| `ModelDecodingTests` | `genreList`: the fixture decodes; first item is `Genre(id: 28, name: "Action")` |
| `NetworkingTests` | `genreListQuery`: path `/3/genre/movie/list`, only `api_key` + `language` |
| | `discoverQuery`: path `/3/discover/movie` with `page`, `with_genres=28`, `sort_by=popularity.desc` |
| `TMDBMovieServiceTests` | `popularWithGenreUsesDiscover`: endpoint is `[.discover(genreID: 28, page: 1)]` |
| | the existing popular test, now with `genreID: nil`: endpoint is still `[.popular(page: 2)]` |
| | `genresRequestsEndpointAndUnwraps`: endpoint `[.movieGenres]`, returns `[Genre]` |
| `MovieListViewModelTests` | `loadGenresPopulatesGenres`: calls are `[.genres]` |
| | `genreLoadFailureDoesNotAffectList`: `genres` empty, `state` untouched; `load()` still succeeds |
| | `selectingGenreResetsToFirstPage`: after loading 7 movies, `selectGenre(28)` gives 5, the last call is `.popular(page: 1, genreID: 28)`, and `canLoadMore` is true |
| | `genreKeptAcrossPaginationAndRefresh`: produces `.popular(page: 2, genreID: 28)`, then `.popular(page: 1, genreID: 28)` |
| | `clearingGenreReturnsToPopular`: `selectGenre(nil)` makes the last call `.popular(page: 1)` |
| | `selectingSameGenreIsNoOp`: no extra calls |
| | `genreSwitchFailureShowsErrorNotStaleMovies`: load, set an error, `selectGenre(28)` gives `.failed`, with `paginationError == nil` |
| `AppShellTests` | `previewDependenciesServeMockData`: update the call; genres not empty; filtering by 28 returns only movies with 28 |

Existing calls to update: `ServiceTests` lines 30, 66, 78 and `AppShellTests` line 26.

To check it: run `swift test`, then open the `MovieListView` preview (it uses the filtering preview service).

## Not included, and risks
- **Left out on purpose:** choosing several genres (`with_genres` AND/OR), remembering the choice between launches, and filtering on the Search tab (TMDB search doesn't support `with_genres`).
- **Ranking difference:** "All Genres" uses `/movie/popular` and a genre uses `/discover/movie`, so the same movie can rank a little differently in the two lists. Moving everything to discover would change how the list behaves today, so I left it alone.
- **Untested race:** no test covers a slow old-genre response arriving after a switch. It relies on the existing `generation` counter, which has no test today either. Testing it would need a mock that can hold a response back.