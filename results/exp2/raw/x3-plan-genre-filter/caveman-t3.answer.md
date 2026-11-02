Plan below. I read the code and changed nothing.

## Design choices

- With no genre selected, keep calling `/movie/popular`. With a genre, call `/discover/movie` with `sort_by=popularity.desc` and `with_genres=<id>`. The result stays "popular" and the existing behavior is unchanged.
- Start with single-select plus an "All" chip. `with_genres` takes a comma for AND and a pipe for OR. Model the selection as `[Int]` in the service and endpoint layers so multi-select needs no later API change. The UI sends one id.
- A genre list failure must not block the movie list. Track genre loading separately.

## Models

- `Models/Genre.swift`: `Genre` already exists and is `Decodable`, `Hashable` and `Sendable`. No change.
- Add `GenreListResponse: Decodable, Sendable` with `let genres: [Genre]`. Put it in `Genre.swift`.
- `PagedResponse<Movie>` is reused for discover. No change.

## Networking

`Networking/Endpoint.swift`:
- Add `case genres` with path `/genre/movie/list`. Its query is only `api_key` and `language`, so add it to the `.movieDetail, .credits` no-extra-items branch.
- Add `case discover(genreIDs: [Int], page: Int)` with path `/discover/movie`. Its query adds:
  - `page`
  - `sort_by=popularity.desc`
  - `with_genres` set to `genreIDs.map(String.init).joined(separator: ",")`. Omit the item when the array is empty.
- `HTTPClient` and `APIError` need no change.

## Service

- `Services/MovieService.swift`: add `func genres() async throws -> [Genre]` and `func discover(genreIDs: [Int], page: Int) async throws -> PagedResponse<Movie>`.
- `Services/TMDBMovieService.swift`: implement both with `client.send`. `genres()` decodes `GenreListResponse` and returns `.genres`.
- `Services/PreviewMovieService.swift`: add the two methods.
  - `genres()` returns a few static genres, for example Action 28 and Science Fiction 878.
  - `discover` returns `Self.movies`.
- `Tests/.../MockMovieService.swift`:
  - Add `Call.genres` and `Call.discover(genreIDs:page:)`.
  - Add fixtures `genres.json` and `discover_page1.json`.
  - Reuse the popular page 2 fixture for the discover page 2 response.

## View model

`ViewModels/MovieListViewModel.swift`:
- New state:
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenre: Genre?`
  - Optional `genresFailed`, if you want a retry affordance.
- `loadGenres() async`:
  - No-op if `genres` is already loaded.
  - On error, leave `genres` empty so the chips hide.
  - Don't touch `state`.
- `selectGenre(_ genre: Genre?) async`:
  - Return early if it equals `selectedGenre`.
  - Set `selectedGenre`, then `generation += 1`.
  - Reset `movies`, `currentPage = 0`, `totalPages = 1`, `paginationError`, `isLoadingNextPage`, `isFetching`.
  - Set `state = .loading`, then `await fetch(page: 1, replacing: true)`.
  - Clear the list immediately. Otherwise the old genre's movies show under the new chip.
- `fetch`: capture `let genre = selectedGenre` before the await. Call `service.popular(page:)` when it is nil, else `service.discover(genreIDs: [genre.id], page:)`.
- `refresh()` and `loadNextPageIfNeeded` already go through `fetch`, so they keep the selected genre.
- Existing `generation` token discards stale responses from the previous genre. Reset `isFetching` explicitly in `selectGenre`. The old fetch's `defer` skips it because its token no longer matches.
- `load()` is guarded by `currentPage == 0`. After `selectGenre` resets the page, `.task { load() }` could refetch on view reappear. Since `selectGenre` fetches itself, `currentPage` becomes ≥1 on success. On failure it stays 0, and `load()` retry is fine.

## View

`Views/MovieListView.swift`:
- Add a `GenreFilterBar` subview, either in a new file `Views/Components/GenreFilterBar.swift` or private in this file. It is a horizontal `ScrollView` of capsule buttons: "All" plus `viewModel.genres`. The selected chip is highlighted and has the `.isSelected` accessibility trait.
- Attach it with `.safeAreaInset(edge: .top)` on `content`, outside the `switch`. Chips stay visible in loading, empty and failed states.
- Add `.task { await viewModel.loadGenres() }` next to the existing `.task`.
- Tapping a chip runs `Task { await viewModel.selectGenre(genre) }`.
- Empty state: when `selectedGenre` is set, use a title like "No \(genre.name) Movies".
- The error view's retry calls `refresh()`, which keeps the genre.
- Hide the bar when `genres.isEmpty`.
- Update `#Preview` only if the signature changes. It doesn't.

`RootView` and `AppDependencies` need no change, because `makeMovieListViewModel` already passes `movieService`.

## Tests

`NetworkingTests`:
- `genresQuery`: path `/3/genre/movie/list`, items `api_key` and `language` only.
- `discoverQuery`: path `/3/discover/movie`, items include `with_genres=28`, `sort_by=popularity.desc` and `page`.
- `discoverMultiGenreQuery`: `[28, 12]` gives `"28,12"`.
- `discoverEmptyGenresOmitsParam`: no `with_genres` item.

`ModelDecodingTests`:
- Decode `genres.json` into `GenreListResponse` and check the count and one name.

`ServiceTests`:
- `genres()` returns the decoded list.
- `discover` sends the right endpoint, with the mock `HTTPClient` or `MockURLProtocol` capturing the request.

`MovieListViewModelTests`:
- `loadGenresPopulatesList`.
- `loadGenresFailureKeepsMoviesUsable`: genre error leaves `genres` empty and `state` unaffected.
- `selectGenreUsesDiscover`: calls are `[.popular(page: 1), .discover(genreIDs: [28], page: 1)]`.
- `selectGenreClearsPreviousResults`: state goes to `.loading` and the old movies are gone before the new result.
- `selectNilReturnsToPopular`: back to the `.popular` call.
- `selectSameGenreIsNoOp`.
- `paginationKeepsGenre`: page 2 calls discover with the same genre.
- `refreshKeepsGenre`.
- `staleResponseDropped`: select A then B quickly. The result must be B's. This needs a mock with a controllable delay, such as an `AsyncStream` or continuation gate in `MockMovieService`.
- `emptyGenreResultShowsEmpty`: use a discover empty fixture.
- `genreErrorShowsFailedThenRetrySucceeds`.

`AppShellTests`: no change expected. Add a smoke check there only if it builds `RootView` with `.preview`.

## Order

1. Models and `Endpoint`, with their tests.
2. `MovieService` protocol, both implementations and `MockMovieService`.
3. View model with tests.
4. View.

Run `swift test` after each step.