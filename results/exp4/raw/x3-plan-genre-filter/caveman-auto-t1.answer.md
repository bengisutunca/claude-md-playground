Here's the plan. I read the current code (the endpoint, the service, the view model and view, and the test doubles) and didn't touch any files.

## Approach

- **Keep `/movie/popular` when no genre is picked.** The default Popular tab stays exactly as it is today. Only when a genre is picked does the list come from `/discover/movie?with_genres=<id>&sort_by=popularity.desc`.
- **One genre at a time.** TMDB's `with_genres` can combine several genres (comma means AND, pipe means OR), but nothing asks for that, so the filter is a single choice: "All" or one genre.
- **If the genre list fails to load, the tab still works.** The filter menu is simply hidden and the movies load as normal.

## Per layer

### Models: `Genre.swift`
- `Genre` already exists and decodes `{id, name}`.
- Add a small `GenreListResponse: Decodable, Sendable { let genres: [Genre] }`, because `/genre/movie/list` wraps the array in `{"genres": [...]}`. It stays file-private to the service layer; callers only ever see `[Genre]`.
- `Movie.genreIDs` already exists, so `Movie` doesn't change.

### Networking: `Endpoint.swift`
- Add two cases: `.genreList` and `.discover(genreID: Int, page: Int)`.
- `path`: `"/genre/movie/list"` and `"/discover/movie"`.
- `queryItems`:
  - `.genreList` uses only the base items (`api_key`, `language`), so it joins `.movieDetail, .credits` in the `break` branch.
  - `.discover` appends `with_genres`, `page` and `sort_by=popularity.desc`. That sort is TMDB's default, but stating it keeps the "popular" meaning visible in the code.
- `HTTPClient` and `APIError` don't change.

### Service: `MovieService.swift`, `TMDBMovieService.swift`, `PreviewMovieService.swift`
- Add two methods to `MovieService`:
  - `func genres() async throws -> [Genre]`
  - `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`

  This keeps the protocol's current one-method-per-endpoint shape, and no existing caller of `popular(page:)` has to change.
- `TMDBMovieService`: `genres()` sends `.genreList` as `GenreListResponse` and returns `.genres`. `discover` sends `.discover(...)` as `PagedResponse<Movie>`.
- `PreviewMovieService`: add a static `genres` list (e.g. Action 28, Sci-Fi 878, Drama 18) and give the sample `movies` matching `genreIDs`. `discover` then filters `movies` by `genreIDs.contains(genreID)`, so the preview shows a working filter.

### View model: `MovieListViewModel.swift`
The paging, deduplication and stale-response handling (`generation`) all stay where they are; the genre choice just feeds into the same fetch.
- New state:
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenre: Genre?`
- In `fetch(page:replacing:)`, change the service call to:
  `selectedGenre.map { try await service.discover(genreID: $0.id, page: page) } ?? try await service.popular(page: page)`
  (or an equivalent `if let`). Pagination and refresh then follow the selected genre automatically.
- `load()` also loads the genres with `async let` alongside page 1. A failure there is swallowed and `genres` stays empty. `refresh()` tries the genres again only if `genres` is empty.
- New `func selectGenre(_ genre: Genre?) async`:
  - Do nothing if `genre == selectedGenre`.
  - Otherwise: set `selectedGenre`, increment `generation` (so a request still running for the old genre is ignored), and clear the old list: `movies = []`, `currentPage = 0`, `totalPages = 1`, `paginationError = nil`, `isLoadingNextPage = false`, `state = .loading`. Then `await fetch(page: 1)`.
  - **Clearing `movies` up front is required.** If it isn't cleared, a failed fetch for the new genre falls into the `paginationError` branch and keeps showing the previous genre's movies under the new filter. Once cleared, the failure correctly becomes `.failed`, and Retry (which calls `refresh()`) retries with the selected genre.

### View: `MovieListView.swift`
- Title: `.navigationTitle(viewModel.selectedGenre?.name ?? "Popular")`.
- Add a `.toolbar` item, shown only when `!viewModel.genres.isEmpty`:
  - a `Menu` with `Label("Genre", systemImage: "line.3.horizontal.decrease.circle")`, which gives VoiceOver a name;
  - inside it, a `Picker` with an "All" row (tag `nil`) followed by each genre (tag `Optional(genre)`);
  - the picker's binding reads `viewModel.selectedGenre` and its setter calls `Task { await viewModel.selectGenre($0) }`.
- `.empty`: when a genre is selected, show "No movies in this genre" in `EmptyStateView`.
- `AppDependencies` and `RootView` don't change.

## Tests

**Fixtures** (`Tests/TMDBAppTests/Fixtures/`):
- `genre_list.json`: a handful of genres.
- `discover_genre_28_page1.json`: a small page whose movies differ from `popular_page1` and whose `total_pages` is greater than 1, so tests can tell the list switched and that paging works.

**`MockMovieService`**:
- Add `Call.genres` and `.discover(genreID:page:)`.
- Add a separate optional `genresError` so a genre failure can be tested on its own.
- `discover` returns the discover fixture for page 1 and `popular_page2` for later pages.

**`ModelDecodingTests`**
- `genreList`: the fixture decodes into `GenreListResponse` with the expected ids and names.

**`NetworkingTests`** (using the existing `parts(_:)` helper)
- `genreListQuery`: path `/3/genre/movie/list`; items exactly `api_key`, `language`.
- `discoverQuery`: path `/3/discover/movie`; items `api_key`, `language`, `with_genres=28`, `page=2`, `sort_by=popularity.desc`.

**`ServiceTests` (`TMDBMovieServiceTests`)**
- `genresRequestsEndpointAndUnwraps`: records `.genreList` and returns `[Genre]`.
- `discoverRequestsEndpointAndDecodes`: records `.discover(genreID:page:)`.

**`MovieListViewModelTests`**
- `loadFetchesGenresAndPopular`: the calls include `.genres` and `.popular(page: 1)`; `genres` is filled; `selectedGenre` is nil.
- `genreFailureDoesNotBlockMovies`: with `genresError` set, `state` is `.loaded` and `genres` is empty.
- `selectGenreReplacesListWithDiscover`: records `.discover(28, 1)`; the state holds only discover results.
- `paginationFollowsSelectedGenre`: after selecting a genre, `loadNextPageIfNeeded` records `.discover(28, 2)`.
- `clearingGenreReturnsToPopular`: `selectGenre(nil)` records `.popular(page: 1)`.
- `selectingSameGenreIsNoOp`: the call count doesn't change.
- `genreSwitchFailureShowsErrorNotStaleMovies`: load popular, set an error, select a genre; `state == .failed`. Clearing the error and calling `refresh()` records `.discover(28, 1)`.
- `refreshKeepsSelectedGenre`.

**Not covered:** a test for a request finishing *after* the user has already switched genre. That needs a mock that can hold a response back, which the current `MockMovieService` can't do. The `generation` mechanism it relies on is the same one `refresh()` already uses. I'd add a suspendable mock only if you want that case pinned down.

To check it once implemented: run `swift test`, plus a manual look at the preview's genre menu.