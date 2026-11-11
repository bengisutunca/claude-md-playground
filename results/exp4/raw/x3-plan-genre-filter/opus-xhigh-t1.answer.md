# Plan: genre filter on the Popular tab

I checked every layer the change touches, plus the tests and fixtures. Nothing was modified. The change fits the existing structure: `Genre` already exists, the view model's `generation` counter already drops results from superseded requests, and none of the existing tests need to change.

## Key decisions

1. **One genre at a time.** A `nil` selection means "All Genres". `with_genres` also accepts `28,12` (all of these genres) or `28|12` (any of them). Moving to multi-select later only means changing the endpoint's associated value to `[Int]`.
2. **"All Genres" keeps using `/movie/popular`.** `/discover/movie` is used only when a genre is selected. This leaves current behaviour and tests alone (`popularQuery`, `firstLoad`'s `calls == [.popular(page: 1)]`).
3. **Genre fetching is separate from `load()`.** A failed genre request only disables the filter; it never puts the movie list into an error state. Keeping it out of `load()` is also what keeps the existing call-sequence assertions valid.

## Models (`Sources/TMDBApp/Models/`)

- **`Genre.swift`:** no change. It's already `Identifiable, Hashable, Sendable, Decodable`, and `Hashable` is what lets it be a `Picker` tag.
- **New `GenreListResponse`** (put it in `Genre.swift`): `struct GenreListResponse: Decodable, Sendable { let genres: [Genre] }`. It matches the `{"genres":[{"id":28,"name":"Action"},…]}` response. That response isn't paged, so `PagedResponse` doesn't fit.
- Discover results are already `PagedResponse<Movie>`.

## Networking (`Networking/Endpoint.swift`)

Add two cases to `Endpoint`:

```swift
case movieGenres                       // path "/genre/movie/list"
case discover(genreID: Int, page: Int) // path "/discover/movie"
```

In `queryItems(apiKey:)`:
- `.movieGenres`: no extra items. Group it with `.movieDetail, .credits` in the `break` branch. It still gets `language=en-US`, so genre names come back in English.
- `.discover`: add `with_genres=<id>`, `page=<n>`, and `sort_by=popularity.desc`. Popularity is TMDB's default sort, but setting it explicitly makes the filtered list mean "popular movies in this genre".

`HTTPClient` / `TMDBClient` stay as they are.

## Service (`Services/`)

**`MovieService.swift`:** add two requirements. A separate `discover` method keeps the `popular(page:)` signature, and every conformer and test using it, unchanged.

```swift
func genres() async throws -> [Genre]
func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>
```

**`TMDBMovieService`:**
- `genres()` calls `client.send(.movieGenres, as: GenreListResponse.self).genres`.
- `discover` sends `.discover(genreID:page:)` and decodes it as `PagedResponse<Movie>`.

**`PreviewMovieService`:**
- Add `static let genres: [Genre]` (Action 28, Adventure 12, Drama 18, Science Fiction 878).
- Give the three sample `movies` real `genreIDs`. They currently have none, so a filtered preview would always be empty.
- `discover` filters `movies` by `genreIDs.contains(genreID)`.

**`AppDependencies` / `RootView`:** no change. `makeMovieListViewModel()` already passes in the shared service.

## View model (`ViewModels/MovieListViewModel.swift`)

New state:

```swift
private(set) var genres: [Genre] = []
private(set) var selectedGenre: Genre?      // nil = All Genres
private var isLoadingGenres = false
```

**`loadGenres() async`**
- Does nothing if `genres` is already filled or a request is in flight.
- Sets `genres = (try? await service.genres()) ?? []`.
- Never touches `state`. If it fails, it simply runs again the next time the view's `.task` fires.

**`selectGenre(_ genre: Genre?) async`**
1. Does nothing if `genre == selectedGenre`.
2. Otherwise: set `selectedGenre`, `generation += 1`, `movies = []`, `currentPage = 0`, `totalPages = 1`, `paginationError = nil`, `isLoadingNextPage = false`, `state = .loading`, then `await fetch(page: 1)`.

**Why it clears up front instead of reusing `refresh()`:** `refresh()` keeps the old movies on screen and only empties them when the request succeeds (`replacing: true`). Two problems follow:
- While loading, Action movies would show under a "Comedy" filter.
- Worse, if that request failed, `movies` would still be non-empty, so `fetch` would set `paginationError` and leave `state` stuck on `.loading`.

Clearing `movies` first means a failure goes to `.failed`. The reset fields could be pulled into a private `resetPaging()` helper.

**`fetch(page:replacing:)`:** this is the only place that needs to know about the filter:

```swift
let response: PagedResponse<Movie>
if let id = selectedGenre?.id {
    response = try await service.discover(genreID: id, page: page)
} else {
    response = try await service.popular(page: page)
}
```

- `loadNextPageIfNeeded` and `refresh()` then keep the selected genre automatically.
- The `generation` token (bumped in `selectGenre`) drops late responses if the user switches genres quickly.
- `ErrorView`'s retry calls `refresh()`, which already re-fetches page 1 for the current genre.

## View (`Views/MovieListView.swift`)

- **Load genres:** add a second `.task { await viewModel.loadGenres() }`. It runs again whenever the view reappears, which gives a free retry after a failure.
- **Filter menu:** add `.toolbar { ToolbarItem(placement: .primaryAction) { genreMenu } }`, where `genreMenu` is a `Menu` wrapping a `Picker`:
  - Options: `Text("All Genres").tag(Genre?.none)` plus `ForEach(viewModel.genres) { Text($0.name).tag(Genre?.some($0)) }`.
  - Selection: `selectedGenre` is `private(set)`, so use a hand-written `Binding` that reads it and whose setter calls `Task { await viewModel.selectGenre($0) }`. This matches how the existing retry buttons start their `Task`s.
  - Label: `selectedGenre?.name ?? "All Genres"`, with `line.3.horizontal.decrease.circle`, switching to `.fill` while a filter is active.
  - `.disabled(viewModel.genres.isEmpty)`.
- **Empty state:** pass a message when filtered, e.g. `"No popular \(genre.name) movies found."`. The toolbar stays visible, so the user can always change genre or clear the filter.
- **Scroll position:** switching genre sets `.loading`, which replaces the `List`, so the new results start at the top.
- The `#Preview` works without changes once `PreviewMovieService` implements the new methods.

## Tests (`Tests/TMDBAppTests/`)

**New fixtures** (`Fixtures/`):
- `genres_movie.json`: a few genres, including 28 "Action".
- `discover_action_page1.json`: `total_pages: 2`, movie IDs different from the popular fixtures, all containing 28.
- `discover_action_page2.json`: the last page.
- Empty genre results reuse `search_empty.json`.
- Add the new names to the list in `SmokeTests.fixturesAreValidJSON`.

**`MockMovieService`:**
- Add `Call.genres` and `Call.discover(genreID:page:)`, and implement both methods.
- `discover` returns the page-1/page-2 fixtures by page, or `search_empty` for a sentinel genre ID (same idea as `search`'s `"empty"` query).
- Add a separate `genresError` with a setter, so a genre failure can be tested while movies still load.

**`ModelDecodingTests`:**
- `genreList`: decodes `GenreListResponse`; checks the count and that the first entry is `Genre(id: 28, name: "Action")`.
- `discoverPage`: every result's `genreIDs` contains 28.

**`NetworkingTests`** (reuse the `parts(_:)` helper):
- `genresQuery`: path `/3/genre/movie/list`; items are only `api_key` and `language`.
- `discoverQuery`: `.discover(genreID: 28, page: 2)` gives path `/3/discover/movie` and items `api_key`, `language`, `with_genres: "28"`, `page: "2"`, `sort_by: "popularity.desc"`.

**`TMDBMovieServiceTests`** (in `ServiceTests.swift`):
- `genresRequestsEndpointAndUnwraps`: `endpoints == [.movieGenres]` and it returns a non-empty `[Genre]`.
- `discoverRequestsEndpointAndDecodes`: `endpoints == [.discover(genreID: 28, page: 1)]`.

**`MovieListViewModelTests`:**

| Test | Checks |
|---|---|
| `loadGenresPopulatesWithoutTouchingState` | `genres` filled, `state == .idle`, calls are `[.genres]` |
| `loadGenresFetchesOnce` | calling twice still gives one `.genres` call |
| `genreFailureDoesNotAffectMovies` | with `genresError` set, movies still load (5) and `genres` stays empty |
| `selectingGenreUsesDiscover` | calls are `[.popular(1), .discover(28, 1)]`; list matches the discover fixture |
| `selectingGenreResetsPagination` | after paging popular to 7 movies, selecting a genre shows the discover page 1 count and `canLoadMore` is true |
| `paginationKeepsGenre` | the next-page call is `.discover(28, 2)` |
| `refreshKeepsGenre` | `refresh()` calls `.discover(28, 1)` |
| `clearingGenreReturnsToPopular` | `selectGenre(nil)` calls `.popular(1)` |
| `selectingSameGenreIsNoOp` | no extra call |
| `genreSwitchFailureShowsError` | after popular loads, set an error and select a genre: `state == .failed`, not stuck on `.loading` and no stale movies; clear the error, `refresh()`, and discover results show |
| `emptyGenreShowsEmptyState` | sentinel genre gives `.empty` |

Optional: a race test showing a late response for the old genre is dropped. This needs a mock that holds responses until released (a continuation); the current mock answers immediately. The existing suite doesn't test the `refresh()` race either.

**`AppShellTests.previewDependenciesServeMockData`:** extend it to check that preview `genres()` isn't empty and that preview `discover` returns only matching movies.

## Order of work

Fixtures and models → `Endpoint` and its tests → `MovieService`, `TMDBMovieService`, `PreviewMovieService` and `MockMovieService` (the protocol change breaks compilation until all three conformers are updated) → view model and its tests → view. Run `swift test` after each step.