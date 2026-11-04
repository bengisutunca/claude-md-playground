## Plan: genre filter on the Popular tab

**Behaviour.** A horizontal chip bar sits above the list. It has an "All" chip plus one chip per genre. "All" keeps today's `/movie/popular`. Choosing a genre switches the list to `/discover/movie?with_genres=<id>&sort_by=popularity.desc`. Pagination, refresh and error handling stay as they are.

**Non-goals.** Multi-select genres, persisting the selection, a genre filter in Search, and caching the genre list across launches.

### Models
- `Models/Genre.swift` already has `id` and `name` and is `Decodable`, so it is reused as is.
- Add a small `GenreList: Decodable` with `genres: [Genre]`. TMDB wraps the list in `{ "genres": [...] }`. If `MovieDetail` has no wrapper to reuse, this is the only new model.

### Networking (`Networking/Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. It needs no extra query items beyond `api_key` and `language`.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. Its query items are `page`, `with_genres` and `sort_by=popularity.desc`.
  - `sort_by` is explicit so a filtered list stays ordered like Popular. This is the one non-obvious choice.
- Add the new cases to the `queryItems(apiKey:)` switch (`.genres` goes in the `.movieDetail, .credits` no-op group).
- `HTTPClient`, `TMDBClient` and `APIError` need no changes.

### Service
- `Services/MovieService.swift`: add `func genres() async throws -> [Genre]` and `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`.
- `Services/TMDBMovieService.swift`:
  - `genres()` sends `.genres` as `GenreList` and returns `.genres`.
  - `discover` sends `.discover(...)` as `PagedResponse<Movie>`.
- `Services/PreviewMovieService.swift`:
  - `genres()` returns two or three static genres, such as Action and Science Fiction, whose ids match the ones in its detail JSON.
  - `discover` returns `Self.movies`.
  - Without these, the protocol change breaks the preview build.

### View model (`ViewModels/MovieListViewModel.swift`)
- Add `private(set) var genres: [Genre] = []` and `private(set) var selectedGenre: Genre?`, where `nil` means All.
- Add `func loadGenres() async`.
  - It is a no-op if genres are already loaded.
  - If it fails, it leaves `genres` empty, so the bar is hidden and the movie list is unaffected. A genre failure must not replace the list with an error screen.
- Add `func select(_ genre: Genre?) async`.
  - It returns early if the genre is unchanged.
  - Otherwise it sets `selectedGenre`, resets state, and calls the existing `refresh()`.
  - `refresh()` already bumps `generation`, so a slow response from the previous filter is dropped. That stale-result protection is the reason to reuse it.
  - It currently keeps old movies visible while refreshing, because `state = .loading` is only set when `movies` is empty. Switching genre should clear `movies` first, so the previous genre's results never appear under the new chip.
- In `fetch(page:replacing:)`, replace `service.popular(page:)` with a branch on `selectedGenre`: `discover(genreID:page:)` when set, `popular(page:)` otherwise. This is the single point where the source is chosen, so pagination and dedupe work for both sources.
- Capture the genre at the start of `fetch` so pagination can't mix sources if the selection changes mid-flight. The `generation` check covers this once `select` goes through `refresh()`.
- `AppDependencies.makeMovieListViewModel()` is unchanged.

### View (`Views/MovieListView.swift`)
- Add a `GenreFilterBar` in `Views/Components/` (or private in the file). It is a horizontal `ScrollView` of buttons for "All" and each genre. The selected chip is highlighted, and each chip has `.accessibilityAddTraits(.isSelected)`.
- Show the bar above `content`, for example with `.safeAreaInset(edge: .top)`, so it stays visible in the loading, empty and failed states. Otherwise the user can't leave a genre that returns nothing.
- Change the task to `.task { await viewModel.loadGenres(); await viewModel.load() }`, or run the two concurrently. Chip taps call `Task { await viewModel.select(genre) }`.
- The empty-state title could mention the selected genre. That is optional.

### Tests (Swift Testing, as in the existing suites)
- **Fixtures.** Add `genres.json` and `discover_page1.json`. The discover fixture should hold different movie ids from `popular_page1`, so tests can tell the sources apart.
- **`MockMovieService`.**
  - Add `Call.genres` and `Call.discover(genreID:page:)`.
  - Add the two methods, with the same `error` handling as the others.
- **`NetworkingTests`.**
  - `genresQuery`: path `/3/genre/movie/list` and the base items.
  - `discoverQuery`: path `/3/discover/movie`, with `with_genres`, `page` and `sort_by` present.
  - A success decode of the `genres` wrapper.
- **`ModelDecodingTests`.** `GenreList` decodes the fixture.
- **`ServiceTests`.** `TMDBMovieService.genres()` and `discover` hit the right endpoints through `MockURLProtocol`.
- **`MovieListViewModelTests`:**
  - `loadGenres` populates `genres` and is idempotent (one `.genres` call).
  - A `loadGenres` failure leaves the list loadable and sets no error state.
  - `select(genre)` calls `.discover(genreID:page:1)`, replaces the movies, and does not call popular.
  - Paging while a genre is selected calls `.discover(page: 2)`.
  - Selecting `nil` returns to `.popular(page: 1)`.
  - Selecting the same genre again makes no call.
  - A stale response is dropped: switch genres while the first request is in flight, and the final state matches the last selection. This needs a mock that can suspend.
  - A discover error shows `.failed`, and `select` followed by `refresh()` recovers.
- **View.** There is no UI-test target, so the chip bar is covered by the view model tests and a `#Preview`.

### Risks
- **Clearing movies on switch.** This changes `refresh()` behaviour only through `select`. Pull-to-refresh must keep its current "keep old movies while reloading" behaviour, which the existing `refreshResetsPages` test covers.
- **Protocol change.** Adding methods to `MovieService` forces updates to `PreviewMovieService` and `MockMovieService`, as listed above.