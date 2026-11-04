# Plan: genre filter on the Popular tab

I read the code but changed nothing. The plan follows the existing layering: `Endpoint` → `MovieService` → `MovieListViewModel` → `MovieListView`.

## Design decisions
- **"All" keeps using `/movie/popular`.** A selected genre switches to `/discover/movie` with `with_genres=<id>` and `sort_by=popularity.desc`, so the order stays comparable to Popular.
- **Single selection first.** TMDB treats a comma in `with_genres` as AND and a pipe as OR. I'd model the selection as `Genre?`, and multi-select can come later.
- **The genre list loads separately and fails separately.** If `/genre/movie/list` fails, the movie list still works and the filter bar is just hidden.

## Models (`Sources/TMDBApp/Models/`)
- `Genre.swift`: already `Decodable` with `id` and `name`, so no change. It is already used in `MovieDetail`.
- Add a small wrapper, `GenreListResponse: Decodable, Sendable { let genres: [Genre] }`. I'd put it in `Genre.swift`, because the endpoint returns `{"genres": [...]}`.
- `PagedResponse<Movie>` is reused as is, since `/discover/movie` returns the same shape.

## Networking (`Networking/Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. It gets only the default `api_key` and `language` items, so add it to the `.movieDetail, .credits` no-extra-params branch in `queryItems`.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie` and these query items: `with_genres=<id>`, `sort_by=popularity.desc`, `page`.
- `HTTPClient` and `TMDBClient` need no change.

## Service
- `Services/MovieService.swift`: add two methods.
  - `func genres() async throws -> [Genre]`
  - `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`
- `TMDBMovieService.swift`: implement both. `genres()` sends `.genres` as `GenreListResponse` and returns `.genres`. `discover` mirrors `popular`.
- `PreviewMovieService.swift`: add static sample genres. For `discover`, return a subset of `movies`.
- `Tests/.../MockMovieService.swift` (a conformer, so it must be updated): add `Call.genres` and `Call.discover(genreID:page:)`. Add fixture-backed implementations (see Tests).
- Run `grep ": MovieService"` to catch any other conformers, for example in `AppShellTests`.

## View model (`ViewModels/MovieListViewModel.swift`)
- New state:
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenre: Genre?`
- `load()`: also fetch genres once, with a failure swallowed into an empty list. Run it concurrently with the first page, for example with `async let`, so it doesn't delay the movies.
- Replace the hard-coded `service.popular(page:)` call in `fetch` with a private `request(page:)`. It calls `discover` if `selectedGenre != nil`, and `popular` otherwise.
- Add `func select(genre: Genre?) async`:
  - Return if the genre is unchanged.
  - Set `selectedGenre`.
  - Bump `generation`, which reuses the existing stale-response protection.
  - Clear `paginationError` and `isLoadingNextPage`.
  - Reset `movies`, `currentPage` and `totalPages`, then set `state = .loading`.
  - Call `fetch(page: 1, replacing: true)`.
- Watch out for `refresh()`: it only shows `.loading` when `movies.isEmpty`. `select` must show `.loading` and clear the old list itself, so the old genre's movies don't flash.
- Also watch out for `isFetching`. The existing `defer` only clears it when the token matches. After a genre switch mid-flight, the new fetch owns the flag, which is correct. A test should confirm that pagination still works afterwards.
- `refresh()` and the Retry button keep the current genre, because `fetch` reads `selectedGenre`.
- The `.empty` state is reachable for a genre with no results. Let the view pick a genre-aware message.

## View (`Views/MovieListView.swift`)
- Add a horizontal `ScrollView` of chips above the list: "All" plus one chip per `viewModel.genres`. The selected chip is highlighted, and tapping one runs `Task { await viewModel.select(genre:) }`.
- Put the bar in a `.safeAreaInset(edge: .top)` on `content`, or in a toolbar `Menu`. It must stay visible in the `.loading`, `.empty` and `.failed` states, or the user can't leave an empty genre. Today `content` is only a switch on state.
- Hide the bar when `genres` is empty.
- Give the chips accessibility labels and the `.isSelected` trait.
- `EmptyStateView` title: "No Movies" for All, "No \(genre.name) Movies" otherwise.
- `AppDependencies` needs no change, because `makeMovieListViewModel` already injects the service.

## Tests (Swift Testing, matching the existing style)
**New fixtures** in `Tests/TMDBAppTests/Fixtures/`:
- `genres.json`
- `discover_page1.json`, plus an empty-results variant

**`ModelDecodingTests`:**
- `GenreListResponse` decodes the fixture.

**`NetworkingTests`:**
- `genresQuery`: path `/3/genre/movie/list`, items are only `api_key` and `language`.
- `discoverQuery`: path `/3/discover/movie`, items include `with_genres=28`, `sort_by=popularity.desc`, `page=2`.
- End-to-end `send` decode of the genre list through `MockURLProtocol`.

**`ServiceTests`:**
- `TMDBMovieService.genres()` and `discover` hit the right endpoints and decode the responses.

**`MovieListViewModelTests`:**
- `load` fetches genres and exposes them.
- A genres failure leaves the movie list `.loaded` and `genres` empty.
- `select(genre:)` calls `.discover(genreID:page: 1)`, replaces the movies, and sets `selectedGenre`.
- Selecting the same genre again makes no extra call.
- Selecting `nil` returns to `.popular(page: 1)`.
- Pagination under a genre calls `.discover(genreID:page: 2)`, not `popular`.
- `refresh()` keeps the selected genre.
- Selecting a genre with empty results gives `.empty`. Then selecting All recovers.
- Switching genre while a request is in flight drops the stale response. This needs a controllable, delayed mock call, in the same spirit as the existing `duplicateCallsWhileLoadingAreIgnored` test.
- A discover error gives `.failed`, and retry succeeds.

**View:** no UI-test infrastructure exists, so the view stays thin and logic lives in the view model. A smoke test in `AppShellTests` could build `MovieListView` with the preview service.

## Suggested order
1. Model, endpoint and service, with the networking and service tests.
2. View model, with its tests.
3. View.
4. Manual check via `AppDependencies.preview`, then with a real key.