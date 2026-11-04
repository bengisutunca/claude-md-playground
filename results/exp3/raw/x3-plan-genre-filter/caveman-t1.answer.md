No files were touched. The plan follows the existing layering: `Endpoint`, then `MovieService`, then `MovieListViewModel`, then `MovieListView`.

## Behavior
- A chip row above the Popular list shows "All" plus the genres from `/genre/movie/list`. The default is "All".
- With "All", the list stays on `/movie/popular`, so current behavior and the existing `.popular(page:)` tests don't change.
- With a genre selected, the list uses `/discover/movie` with `with_genres=<id>` and `sort_by=popularity.desc`. This keeps the "Popular" meaning. Pagination, refresh and retry keep the selected genre.
- Selection is single genre only. TMDB's comma means AND and pipe means OR, so multi-select would need a product decision, and I'd leave it out.
- If the genre list fails to load, the chip row stays hidden and the list still works. A genre failure is not a screen error.

## Models
- `Models/Genre.swift`: `Genre` is already `Decodable`, `Hashable` and `Identifiable`. Add `struct GenreListResponse: Decodable, Sendable { let genres: [Genre] }`, because the endpoint returns `{"genres":[…]}`.
- `PagedResponse<Movie>` and `JSONDecoder.tmdb` are reused unchanged.

## Networking
In `Networking/Endpoint.swift`:
- Add `case genres` with path `/genre/movie/list`. It uses only the base `api_key` and `language` items.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. Extra query items are `page`, `with_genres` and `sort_by=popularity.desc`.
- Add the new cases to `path` and `queryItems`. Nothing changes in `HTTPClient` or `APIError`.

## Service
- `Services/MovieService.swift`: add `genres() async throws -> [Genre]` and `discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`.
- I'd add `discover` rather than a `genreID:` parameter on `popular`. A parameter would change the signature that `MockMovieService.Call.popular(page:)` and the existing tests use.
- `TMDBMovieService`: `genres()` sends `.genres` as `GenreListResponse` and returns `.genres`. `discover` sends `.discover`.
- `PreviewMovieService`: add a static genre list. `discover` can return a subset of `movies` for previews.

## View model
Changes in `ViewModels/MovieListViewModel.swift`:
- Add `private(set) var genres: [Genre] = []` and `private(set) var selectedGenre: Genre?`.
- Add `loadGenres()`, which swallows errors and is a no-op once genres are loaded.
- Add `select(_ genre: Genre?)`:
  - Return early if the genre is unchanged.
  - Bump `generation`, which drops in-flight results the way `refresh()` does.
  - Reset `movies`, `currentPage` and `totalPages`, clear `paginationError` and `isLoadingNextPage`, and set `state = .loading`.
  - Call `fetch(page: 1)`.
- In `fetch`, capture `selectedGenre` at the start. Call `service.discover(genreID:page:)` if it's set, otherwise `service.popular(page:)`. The existing `generation` token already discards stale results.
- `loadGenres()` is separate from `load()` on purpose. The view calls it from its own task, so `load()` and the existing assertions like `calls == [.popular(page: 1)]` stay unchanged.

## View
Changes in `Views/MovieListView.swift`:
- Wrap the content in `VStack(spacing: 0) { genreBar; content }`. The bar has to stay visible in the loading, empty and failed states so the user can switch away from a genre with no results.
- `genreBar` is a horizontal `ScrollView` of buttons: "All", then each genre. The selected one gets a filled style and `.accessibilityAddTraits(.isSelected)`.
- Each button runs `Task { await viewModel.select(genre) }`.
- Add `.task { await viewModel.loadGenres() }` next to the existing `.task`.
- The bar renders only when `genres` is non-empty.
- The list is rebuilt through `.loading` on a genre change, so scroll position resets without extra code.

## Tests
Use Swift Testing, as the existing suites do.

- **`NetworkingTests`**
  - `.genres` has path `/3/genre/movie/list` and no `page` item.
  - `.discover(genreID: 28, page: 2)` has path `/3/discover/movie` with `with_genres=28`, `page=2` and `sort_by=popularity.desc`.
- **`ModelDecodingTests`**: add a `genre_list` fixture and decode `GenreListResponse`.
- **`ServiceTests`**: with `MockHTTPClient`, `genres()` hits `[.genres]` and returns the decoded genres. `discover` records `.discover(genreID:page:)`.
- **`MockMovieService`**
  - Add `Call.genres` and `Call.discover(genreID:page:)`.
  - Return the existing popular or search fixtures for `discover`, and a `genre_list` fixture for `genres()`.
- **`MovieListViewModelTests`**
  - `loadGenres` populates `genres`.
  - A `loadGenres` error leaves `genres` empty and `state` untouched.
  - `select(genre)` after `load()` replaces the list, and `calls` ends with `.discover(genreID:, page: 1)`.
  - Pagination after a selection calls `.discover(…, page: 2)` with the same genre.
  - `select(nil)` goes back to `.popular(page: 1)`.
  - Selecting the same genre again makes no extra call.
  - An error on select gives `.failed`, and `refresh()` recovers.
  - A stale response is dropped: select A, then B before A returns. This needs a mock that can hold a response, so I'd add a small gated variant of the mock.
  - `refresh()` keeps the selected genre.
- The existing view model tests should pass unchanged. That confirms the default path is untouched.

## Open question
Is single-select right? Multi-select would add AND/OR semantics to `Endpoint.discover`, and the chip row would need a selected set instead of one genre.