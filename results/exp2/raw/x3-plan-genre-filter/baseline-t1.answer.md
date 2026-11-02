# Plan: genre filter on the Popular tab

Nothing has been modified. This plan comes from reading `Endpoint`, `MovieService`, `TMDBMovieService`, `MovieListViewModel`, `MovieListView`, `RootView`, `AppDependencies`, `PreviewMovieService`, and the existing tests.

## Design decisions

- **Two data sources.** With no genre selected, keep calling `/movie/popular`. With a genre selected, call `/discover/movie?with_genres=<id>&sort_by=popularity.desc`. `/movie/popular` has no genre parameter, so the filter needs `/discover/movie`, and sorting by popularity keeps the results consistent with the unfiltered list.
- **One genre at a time.** Single-select is the simplest UI and API shape. `with_genres` accepts comma-separated IDs (AND) or pipe-separated IDs (OR), so the type can later allow a set of genres. I'd keep the API as `genreID: Int?` for now.
- **Reuse `Genre`.** `Models/Genre.swift` already has `id` and `name` and is `Decodable`, `Hashable` and `Sendable`. It is currently used by `MovieDetail`.

## Models

- Add `GenreListResponse: Decodable, Sendable`, with `genres: [Genre]`. It can go in `Models/Genre.swift`.
- `Genre` and `PagedResponse<Movie>` need no change, because `/discover/movie` returns the same paged shape as `/movie/popular`.

## Networking (`Networking/Endpoint.swift`)

- Add two cases:
  - `.genres`, with path `/genre/movie/list`.
  - `.discover(genreID: Int, page: Int)`, with path `/discover/movie`.
- In `queryItems(apiKey:)`:
  - `.discover` adds `with_genres=<id>`, `sort_by=popularity.desc` and `page`.
  - `.genres` adds nothing beyond the default `api_key` and `language`.
  - The `switch` is exhaustive, so the compiler will point to every place that needs updating.
- `HTTPClient.swift` and `APIError.swift` need no change.

## Service

- `Services/MovieService.swift`: add two methods.
  - `func genres() async throws -> [Genre]`
  - `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`
- `Services/TMDBMovieService.swift`: implement both with `client.send`. `genres()` decodes `GenreListResponse` and returns `.genres`.
- `Services/PreviewMovieService.swift`: add a static genre list (for example Action 28 and Science Fiction 878, matching the existing detail JSON). `discover` returns a subset of `Self.movies`.
- Adding protocol methods breaks every conformer. That means `TMDBMovieService`, `PreviewMovieService` and the test `MockMovieService`, so all three must be updated together.

## View model (`ViewModels/MovieListViewModel.swift`)

- **New state**
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenre: Genre?` (`nil` means "All")
  - Optionally `genresError`. A failed genre list should not block the movie list, so it only hides or disables the filter, or shows a small retry.
- **`load()`**
  - Fetch the movies and the genres concurrently with `async let`, or in a child `Task`. The genres fetch must not change `state`.
  - Keep the existing guards (`!isFetching`, `currentPage == 0`).
- **`selectGenre(_ genre: Genre?)`**
  - Do nothing if the genre is unchanged.
  - Set `selectedGenre`, reset `movies`, `currentPage`, `totalPages` and `paginationError`, set `state = .loading`, then `await fetch(page: 1, replacing: true)`.
  - Increment `generation` first. The existing token mechanism then drops results from a superseded request, such as a quick switch from Action to Comedy. This is the main correctness risk.
- **`fetch(page:replacing:)`**
  - Branch on `selectedGenre`: `service.discover(genreID:page:)` if set, otherwise `service.popular(page:)`.
  - Capture the genre at the start of the call, so a page-2 response can't be appended to a different genre's list.
- **`refresh()` and `loadNextPageIfNeeded`**
  - Both go through `fetch`, so they follow the selected genre.
  - `isFetching` is only cleared when `token == generation`. Make sure `selectGenre` while a request is in flight doesn't leave `isFetching` stuck true. The current `guard !isFetching` in `loadNextPageIfNeeded` would then block pagination. `refresh()` has the same hazard today.
- **Empty result**
  - A genre with no results gives `.empty`. Now that filtering exists, the empty-state view should be able to say "No movies in this genre".

## View (`Views/MovieListView.swift`)

- Add a toolbar `Menu` with a `Picker` (or a horizontal chip row above the `List`). I'd pick the toolbar menu: it is the smaller change and works with the existing `List`/`refreshable` structure.
  - Items: "All" plus `viewModel.genres`.
  - The selection binding calls `Task { await viewModel.selectGenre(...) }`.
  - Show the active genre in the label, for example a `line.3.horizontal.decrease.circle` icon, filled when a filter is active.
  - Hide or disable it while `genres` is empty.
- The filter must stay reachable in the `.empty` and `.failed` states, so it shouldn't live inside the `.loaded` branch of `content`. Putting it in `.toolbar` on the outer view handles this.
- When the filter is active, the title could change to the genre name (optional).
- Update the `#Preview` only if `PreviewMovieService` needs to show genres, which it will.

## Composition

- `AppDependencies.swift` and `RootView.swift` need no change. `MovieListViewModel(service:)` already takes the shared service.

## Tests

**`NetworkingTests.swift`** (query construction, no network)
- `genresQuery`: path `/3/genre/movie/list`, items `api_key` and `language` only.
- `discoverQuery`: path `/3/discover/movie`, items include `with_genres=28`, `sort_by=popularity.desc` and `page=2`.
- `genresDecode`: the client decodes the new fixture into `GenreListResponse`.

**`ModelDecodingTests.swift`**
- Decode `genres.json` into `GenreListResponse`, checking the count and the first id and name.

**New fixtures in `Tests/TMDBAppTests/Fixtures/`**
- `genres.json`, in the TMDB shape `{"genres":[{"id":28,"name":"Action"},…]}`.
- `discover_action_page1.json`, plus optionally a page 2 with different movie IDs from the popular fixtures, so tests can tell the two sources apart.

**`MockMovieService.swift`**
- Add `.genres` and `.discover(genreID:page:)` to `Call`, and implement the two new methods using the fixtures.
- Optionally support a per-call delay or a controllable continuation, for the race test below.

**`MovieListViewModelTests.swift`**
- `loadFetchesGenres`: after `load()`, `genres` is populated and the calls include `.popular(page: 1)` and `.genres`.
- `genreFailureDoesNotBreakList`: if only the genre call throws, movies are still `.loaded` and `genres` is empty.
- `selectGenreUsesDiscover`: after `selectGenre`, the call is `.discover(genreID:page:1)` and the list shows the discover fixture's movies.
- `selectGenreResetsPaginationAndReplacesList`: after loading page 2 of popular, selecting a genre leaves only the filtered results and calls page 1.
- `paginationFollowsSelectedGenre`: with a genre selected, the next page calls `.discover(genreID:page:2)`, not `.popular`.
- `clearingGenreReturnsToPopular`: `selectGenre(nil)` goes back to `.popular(page: 1)`.
- `selectingSameGenreIsNoOp`: no extra calls.
- `staleResponseIsDropped`: switch genres quickly. The slow earlier response must not overwrite the later selection (this tests the `generation` logic).
- `emptyGenreResultShowsEmptyState`: add a discover-empty fixture and check `state == .empty`.
- `refreshKeepsSelectedGenre`: `refresh()` calls `discover`, not `popular`.
- `errorOnGenreSwitchShowsFailed`: if the first genre-switch request fails, `state` becomes `.failed`, and a retry via `refresh()` recovers.

**`ServiceTests.swift`**
- `TMDBMovieService.genres()` and `.discover(...)` hit the expected endpoints, using the `MockURLProtocol` pattern already used there.

**`AppShellTests.swift`**
- Update only if it asserts on `MovieListView` or preview service behavior. Otherwise it's unaffected.

## Suggested order

1. Models, `Endpoint` and the endpoint tests, plus fixtures.
2. Service protocol and all three conformers, plus service tests.
3. View model and its tests.
4. View and preview.

## Open questions

- Single-select or multi-select? The plan above assumes single.
- Should the genre list be cached across refreshes? It rarely changes, so fetching once per view model lifetime is enough, and `refresh()` could skip it unless the first fetch failed.
- Should the selected genre persist across launches? I'd say no for now.