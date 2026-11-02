Plan only. I changed no files.

**Design decisions**
- Single-select genre, with "All" as the default. This is simplest, and `with_genres` also accepts comma (AND) or pipe (OR) lists if you want multi-select later.
- The Popular tab currently calls `/movie/popular`. That endpoint has no genre parameter, so a selected genre must switch to `/discover/movie?with_genres=<id>&sort_by=popularity.desc`. "All" keeps using `/movie/popular`. This keeps current behavior and test expectations unchanged.
- The genre list is fetched once per session. A failed genre fetch must not block the movie list: hide the chips, or show a retry.

**Models** (`Sources/TMDBApp/Models/`)
- Reuse `Genre` in `Genre.swift`. It already has `id` and `name`, and `Decodable`.
- Add `GenreListResponse: Decodable, Sendable` with `genres: [Genre]`. The `/genre/movie/list` body is `{"genres": [...]}`, not paged, so `PagedResponse` does not fit.

**Networking** (`Networking/Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. It needs only the default `api_key` and `language` items. Add it to the `.movieDetail, .credits` no-extra-params branch in `queryItems`.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. Its query items are `page`, `with_genres=<id>` and `sort_by=popularity.desc`.
- `Endpoint` is an exhaustive `switch`, so the compiler will point at every spot to update.

**Service**
- `MovieService.swift`: add `func genres() async throws -> [Genre]` and `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`.
- `TMDBMovieService.swift`: implement both with `client.send`. `genres()` decodes `GenreListResponse` and returns `.genres`.
- `PreviewMovieService.swift`: add the two methods.
  - `genres()` returns a few static genres, e.g. Action 28 and Science Fiction 878, taken from `detailJSON`.
  - `discover` returns the static movies. Filtering by genre needs a `genreIDs` field on `Movie`, which is not there, so return the static movies as-is.
- Option: fold both into one `popular(page:genreID:)` method. I prefer the two separate methods, because each one maps to one endpoint.

**View model** (`ViewModels/MovieListViewModel.swift`)
- Add `private(set) var genres: [Genre] = []` and `private(set) var selectedGenre: Genre?`, where `nil` means All.
- Add `func loadGenres() async`. It is a no-op if `genres` is already loaded. It swallows errors, so the list still works without genres.
- Add `func select(genre: Genre?) async`.
  - It returns early if the selection is unchanged.
  - Otherwise it sets `selectedGenre`, resets `movies`, `currentPage` and `totalPages`, bumps `generation`, sets `state = .loading`, and calls `fetch(page: 1, replacing: true)`.
  - The existing `generation` token already drops stale results from a superseded request, e.g. when the user taps chips quickly.
- `fetch(page:replacing:)`: choose `service.discover(genreID:page:)` when `selectedGenre` is non-nil, else `service.popular(page:)`.
- `refresh()` and `loadNextPageIfNeeded` need no change. Both go through `fetch`, so they keep the active genre.
- Decide the `.empty` state for a genre with no results. The existing `EmptyStateView` is enough.

**View** (`Views/MovieListView.swift`)
- Add a horizontal `ScrollView` of chips above the list: "All" plus one chip per `viewModel.genres`. Highlight the selected chip and call `Task { await viewModel.select(genre:) }` on tap.
- Restructure `content` so the chip bar stays visible in every state (loading, empty, failed, loaded). Otherwise the user cannot change genre from an empty or error state. For example, put a `VStack { GenreFilterBar; content }` in `body`.
- Add `.task { await viewModel.loadGenres() }` next to the existing `.task { await viewModel.load() }`.
- Put the chip bar in a new `Views/Components/GenreFilterView.swift`, which takes `genres`, `selected` and an `onSelect` closure. `RootView` and `AppDependencies` need no change, because the service is already injected.

**Tests** (Swift Testing, in `Tests/TMDBAppTests/`)
- Fixtures: add `genres.json` (`{"genres":[{"id":28,"name":"Action"}, …]}`) and `discover_action.json` (paged, 2-3 movies). Optionally add a `discover_action_page2.json`.
- `MockMovieService.swift`:
  - Add `genres` and `discover(genreID:page:)` to the `Call` enum.
  - Add the two methods, serving the new fixtures.
- `NetworkingTests.swift`:
  - `genresQuery`: path `/3/genre/movie/list`, items are only `api_key` and `language`.
  - `discoverQuery`: path `/3/discover/movie`, with `with_genres=28`, `page=2` and `sort_by=popularity.desc`.
- `ModelDecodingTests.swift`: decode `GenreListResponse` from `genres.json`.
- `ServiceTests.swift`: `genresRequestsEndpointAndDecodes` and `discoverRequestsEndpointAndDecodes`. They use the existing stub `HTTPClient` that records endpoints. Also add a client-error propagation case.
- `MovieListViewModelTests.swift`:
  - `loadGenresPopulatesOnce`: a second call makes no extra service call.
  - `genresFailureDoesNotBreakList`: the genre fetch throws, yet `load()` still ends `.loaded`.
  - `selectGenreUsesDiscoverAndResets`: after `select`, the calls are `[.popular(1), .discover(28, 1)]`, and the movies come from the discover fixture.
  - `selectAllReturnsToPopular`: `select(genre: nil)` calls popular again.
  - `selectSameGenreIsNoOp`.
  - `paginationKeepsGenre`: the next page calls `.discover(genreID: 28, page: 2)`.
  - `refreshKeepsGenre`.
  - `rapidSelectionDropsStaleResults`: a slow first selection followed by a second one means only the second result is shown.
  - `emptyGenreShowsEmptyState` and `genreFetchErrorShowsFailed`.
- `AppShellTests.swift`: extend `previewDependenciesServeMockData` to check that `genres()` and `discover` work on `PreviewMovieService`.
- The view has no existing UI tests, so skip view tests. Cover the view with the `#Preview` only.

**Order of work**
1. Models and `Endpoint`.
2. `MovieService`, `TMDBMovieService`, `PreviewMovieService` and `MockMovieService`, so everything compiles.
3. Networking and service tests.
4. View model and its tests.
5. View.

**Open questions**
- Should "All" stay on `/movie/popular`, or switch to `/discover/movie` with no genre? A single endpoint would simplify the view model, but the result order may differ slightly.
- Do you want multi-select now or later?