# Plan: genre filter on the Popular tab

## What the code looks like now

- `Genre` (`Models/Genre.swift`) already exists as `id` and `name`, `Decodable`. It's used by `MovieDetail`.
- `Endpoint` has `popular`, `search`, `movieDetail` and `credits`. Each has its own `path` and `queryItems`.
- `MovieService` has four methods, implemented by `TMDBMovieService`, `PreviewMovieService` and the test double `MockMovieService`.
- `MovieListViewModel` loads and paginates only through `service.popular(page:)`. It has a `generation` counter that drops stale responses, and `refresh()` resets the list.
- `MovieListView` is hosted in a `NavigationStack` from `RootView`.
- `AppDependencies.makeMovieListViewModel()` builds the view model.

## Design decisions

1. **"All" keeps using `/movie/popular`.** Only a selected genre switches to `/discover/movie?with_genres=<id>&sort_by=popularity.desc`. This leaves the current behaviour and its tests unchanged.
2. **Single-select.** The state is `Genre?`, where `nil` means All. `with_genres` also supports `,` (AND) and `|` (OR), so multi-select can be added later without changing the endpoint. It only needs the parameter value built from a collection.
3. **The genre list loads separately from the movies.** If `/genre/movie/list` fails, the movie list still works and the filter bar is hidden.

## Changes by layer

### Models
- Add `GenreListResponse` in `Models/Genre.swift`. It is `Decodable, Sendable` with `let genres: [Genre]`. No custom keys are needed.
- `Genre` and `Movie` need no changes. Discover returns the same `PagedResponse<Movie>` shape.

### Networking (`Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. Its query is the default `api_key` and `language` only.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. Its query adds `with_genres=<id>`, `sort_by=popularity.desc` and `page`.
- Extend the `switch` in `queryItems(apiKey:)`. `.genres` goes in the no-extra-params branch.
- `HTTPClient` and `TMDBClient` need no changes.

### Service
- In `MovieService`, add `func genres() async throws -> [Genre]` and `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`.
- `TMDBMovieService`: implement both with `client.send`. `genres()` decodes `GenreListResponse` and returns `.genres`.
- `PreviewMovieService`: return a static genre list. For `discover`, filter `movies` by genre. That needs a `genreIDs` field on the sample data, or it can simply return all of them.
- `Tests/.../MockMovieService`: add `Call.genres` and `Call.discover(genreID:page:)`. Add fixtures `genres.json` and `discover_page1.json`.

### View model (`MovieListViewModel`)
- Add observable state: `private(set) var genres: [Genre] = []` and `private(set) var selectedGenre: Genre?`.
- Add `loadGenres() async`. It is idempotent and swallows errors, leaving `genres` empty.
- Add `selectGenre(_ genre: Genre?) async`:
  - Return early if the selection is unchanged.
  - Set `selectedGenre`.
  - Reset `movies`, `currentPage`, `totalPages` and `paginationError`.
  - Increment `generation`, so any in-flight request for the old filter is discarded.
  - Set `state = .loading` and call `fetch(page: 1, replacing: true)`.
- In `fetch`, replace the direct `service.popular` call with a private `fetchPage(_:)`. It calls `popular` when `selectedGenre == nil` and `discover` otherwise. Pagination, dedupe and error handling stay as they are.
- `load()` should start genres and the first page together, for example with `async let`. A failed genres call must not fail the page.
- **Edge case:** `refresh()` must keep the selected genre. Pagination uses the current filter, because it goes through `fetchPage`.
- **Edge case:** `isFetching` is only cleared when the token matches. After a genre switch, the old request's `defer` is skipped and the new one clears it. This holds if `selectGenre` resets `isFetching = false` itself, as `refresh` effectively does, so I'd check that carefully.

### View (`MovieListView`)
- Add a horizontal `ScrollView` of chips above the `List`: an "All" chip plus one per genre. The selected chip is highlighted and a tap calls `Task { await viewModel.selectGenre(g) }`. Put it in a new `Views/Components/GenreFilterBar.swift`, taking `genres`, `selected` and `onSelect`. It can be previewed on its own.
- Show it with `.safeAreaInset(edge: .top)` so it is visible in the loaded, empty and error states. Hide it when `genres.isEmpty`.
- Add `.task { await viewModel.loadGenres() }` next to the existing `load()` task.
- Make the empty state genre-aware, for example "No \(genre.name) movies".
- No change is needed in `RootView` or `AppDependencies`. The view model's init signature stays the same.

## Tests to add

All are Swift Testing, and none touch the network.

**`NetworkingTests`**
- `genresQuery`: the path is `/genre/movie/list` and the query has `api_key` and `language`.
- `discoverQuery`: the path is `/discover/movie` and the query has `with_genres=28`, `page`, and `sort_by=popularity.desc`.

**`ModelDecodingTests`**
- `genreList`: `genres.json` decodes into `GenreListResponse` with the expected ids and names.

**`ServiceTests`**
- `genresRequestsEndpointAndDecodes`: the endpoint is `.genres` and the result is the unwrapped `[Genre]`.
- `discoverRequestsEndpointAndDecodes`: the endpoint is `.discover(genreID:page:)`.
- The existing error-propagation test pattern covers the new methods.
- Update the `MockMovieService` self-tests for the new calls.

**`MovieListViewModelTests`**
- `loadGenresPopulatesList`.
- `genresFailureDoesNotBreakMovieList`: the movies are `.loaded` and `genres` is empty.
- `selectGenreFetchesDiscoverPage1`: calls are `[.popular(1), .discover(28, 1)]` and the list is replaced.
- `selectGenreResetsPagination`: select a genre, then page 2 uses `.discover(genreID:, page: 2)`.
- `selectNilReturnsToPopular`: after "All", calls use `.popular` again.
- `selectingSameGenreIsNoOp`: no extra service call.
- `refreshKeepsSelectedGenre`.
- `staleResponseDroppedOnGenreSwitch`: a controllable mock (gated continuation) shows that a slow response for genre A does not overwrite genre B's results.
- `discoverErrorShowsFailedStateAndRetryWorks`.
- `emptyGenreResultsShowEmptyState`.

**`AppShellTests`**
- Extend `previewDependenciesServeMockData` to cover preview `genres()` and `discover`.

## Suggested order

1. Models and `Endpoint`, with their tests.
2. Service protocol and implementations. This breaks the build until `MockMovieService` and `PreviewMovieService` are updated, so do all three together.
3. View model, with tests.
4. View and `GenreFilterBar`.

The stale-response test is the one most likely to catch a real bug, so I'd write it first.

I made no changes to any file.