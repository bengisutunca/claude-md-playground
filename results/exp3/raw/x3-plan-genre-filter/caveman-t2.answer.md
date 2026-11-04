# Plan: genre filter on the Popular tab

I only read files, and changed nothing.

## Design decision
When no genre is selected, keep using `/movie/popular`. When one is selected, call `/discover/movie?with_genres=<id>&sort_by=popularity.desc`. `/movie/popular` can't filter. `/discover/movie` with `sort_by=popularity.desc` gives a similar ordering, though TMDB doesn't guarantee it is identical. Keeping the unfiltered path as it is means the existing popular tests and fixtures stay valid.

I'd keep one service method, `popular(page:genreID:)`, rather than adding a separate `discover` method. `MovieListViewModel` then has a single fetch path, and the choice of endpoint stays in the networking layer.

## Per layer

**Models**
- `Models/Genre.swift` already has `id` and `name`, and `MovieDetail` uses it. It needs no change.
- Add `GenreListResponse: Decodable { let genres: [Genre] }`, either in `Genre.swift` or its own file. The `/genre/movie/list` response is `{"genres": [...]}`, not a paged response.

**Networking** (`Networking/Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. It needs no extra query items, because `api_key` and `language` are already added to every request.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. In `queryItems` it adds `with_genres`, `sort_by=popularity.desc` and `page`.
- Extend the `path` and `queryItems` switches. `queryItems` groups `.movieDetail, .credits` under `break`, so `.genres` goes there.

**Service**
- In `Services/MovieService.swift`:
  - Change `popular(page:)` to `popular(page:genreID: Int?)`, or add a default via a protocol extension.
  - Add `genres() async throws -> [Genre]`.
- In `Services/TMDBMovieService.swift`:
  - `popular` sends `.discover(...)` when `genreID` is non-nil, and `.popular(...)` otherwise.
  - `genres()` sends `.genres` as `GenreListResponse` and returns `.genres`.
- In `Services/PreviewMovieService.swift`:
  - Return a few static genres.
  - Filter the sample movies by genre if `Movie` carries `genreIDs`. Otherwise just return all of them.
- `Movie` may need a decoded `genre_ids` field for this. I haven't checked `Models/Movie.swift`, and the preview only needs it if I want filtering there.

**View model** (`ViewModels/MovieListViewModel.swift`)
- Add `private(set) var genres: [Genre] = []` and `private(set) var selectedGenre: Genre?` (nil means "All").
- Add `loadGenres()`, which fetches once. If it fails, the filter stays hidden or empty and the movie list is unaffected. A genre-list failure shouldn't block the popular list.
- Add `select(_ genre: Genre?)`. If the genre is the same, do nothing. Otherwise set `selectedGenre`, reset `currentPage` and `totalPages` to 0 and 1, and clear `movies`. Then call `refresh()`.
- `fetch` passes `selectedGenre?.id` to the service.
- The existing `generation` token already drops stale responses when the user switches genres quickly. `refresh()` increments it, so `select` should go through `refresh()`. Because `refresh()` only shows `.loading` when `movies.isEmpty`, `select` must clear `movies` first, otherwise the old genre's list stays on screen.
- `.empty` already covers a genre with no results. The empty-state title could say "No Movies in <genre>", but that's optional.

**View** (`Views/MovieListView.swift`)
- Add a horizontal chip bar above the list: an "All" chip plus one chip per genre. Alternatively, a toolbar `Menu` with a `Picker`, which is less layout work and fits the navigation bar.
- Run `.task { await viewModel.load() }` and `.task { await viewModel.loadGenres() }` in parallel.
- Add accessibility labels and the selected trait on the chips.
- Show the filter bar in the `.empty` and `.failed` states too. Otherwise a genre that returns nothing leaves the user stuck. That means restructuring `content` so the filter sits outside the `switch`.
- `AppDependencies` and `RootView` should need no changes, since the service is already injected. I haven't read those two files.

## Tests
All under `Tests/TMDBAppTests`.

- **`MockMovieService.swift`:**
  - Add `Call.popular(page:genreID:)` and `Call.genres`.
  - Add a `genres()` stub that returns a new fixture `genres.json`, and a way to make it fail independently of `popular`.
  - Update the existing call assertions to the new signature.
- **`Fixtures/genres.json`:** a small `{"genres":[...]}` sample, plus a `discover_action_page1.json` if the mock should return different data per genre.
- **`ModelDecodingTests`:** `GenreListResponse` decodes the fixture.
- **`NetworkingTests`** (the URL-building tests):
  - `.genres` builds `/genre/movie/list` with `api_key` and `language`.
  - `.discover(genreID: 28, page: 2)` builds `/discover/movie` with `with_genres=28`, `sort_by=popularity.desc` and `page=2`.
  - `.popular` still has no `with_genres`.
- **`ServiceTests`** (using `MockURLProtocol`):
  - `popular(page:genreID: nil)` hits `/movie/popular`.
  - `popular(page:genreID: 28)` hits `/discover/movie`.
  - `genres()` returns the decoded array.
  - A 401 on `genres()` maps to the existing `APIError`.
- **`MovieListViewModelTests`:**
  - `loadGenres` populates `genres`, and a failure leaves `genres` empty without affecting `state`.
  - `select(genre)` refetches page 1 with that `genreID`, replaces the movies, and resets pagination.
  - Selecting the same genre again makes no extra call.
  - Selecting nil goes back to unfiltered.
  - A slow response for the old genre arriving after a new selection is discarded (the `generation` race).
  - Pagination after selecting a genre requests page 2 with the same `genreID`.
  - An empty result gives `.empty`.
- **`AppShellTests`:** only if it asserts on `MovieListView` or `MovieListViewModel` construction. Otherwise no change.

## Risks and open points
- The `popular(page:)` signature change touches every `MovieService` conformer (`TMDBMovieService`, `PreviewMovieService`, `MockMovieService`) and their call sites. A default parameter value can't satisfy a protocol requirement, so either the protocol extension supplies the old one-argument form, or the tests are updated.
- Whether to show genres as chips or a menu is a UI choice. I'd go with the toolbar menu for the least code.
- The genre list is cached only in the view model for its lifetime. TMDB's list changes rarely, so I'd skip persisting it.
- If you'd rather always use `/discover/movie` and drop `/movie/popular`, the layers are the same, but the popular fixtures and tests would need rewriting.