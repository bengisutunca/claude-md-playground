Plan: no genre selected keeps `/movie/popular`. A selected genre switches to `/discover/movie?sort_by=popularity.desc&with_genres=<id>`. Unfiltered behavior and tests stay unchanged.

## Models
- `Genre` (`Models/Genre.swift`) already has `id` and `name`, and it is `Decodable`. Reuse it.
- Add `GenreListResponse: Decodable, Sendable` with `genres: [Genre]`. TMDB wraps the list in `{"genres": [...]}`. Put it in `Models/Genre.swift` or a new file.

## Networking
In `Endpoint` (`Networking/Endpoint.swift`):
- Add `case genres`. Its path is `/genre/movie/list`. Its `queryItems` branch is a no-op, next to `.movieDetail, .credits`.
- Add `case discover(genreID: Int, page: Int)`. Its path is `/movie/discover`... no: use `/discover/movie`. Its query items are `sort_by=popularity.desc`, `with_genres=<id>`, `page=<n>`.
- Keep `.popular(page:)` for the unfiltered case.
- Single genre only, so there is no `,` (AND) or `|` (OR) joining. A later multi-select would change `genreID` to a set.

## Service
- `MovieService` (`Services/MovieService.swift`): add `func genres() async throws -> [Genre]`.
- Change `popular(page:)` to `popular(page: Int, genreID: Int?)`. A nil `genreID` means no filter.
- `TMDBMovieService`: `popular` picks `.popular` or `.discover` by `genreID`. `genres()` sends `.genres` as `GenreListResponse` and returns `.genres`.
- `PreviewMovieService`: return a static genre list. Filter `movies` by genre. This needs a `genreIDs` field on `Movie`. Check whether `Movie` has it, because `/discover/movie` results carry `genre_ids`. If the field is absent, add it as optional so existing fixtures still decode. Otherwise the preview ignores the filter.
- `MockMovieService` (tests): add `Call.popular(page:genreID:)` and `Call.genres`. Add a `genres` fixture. Update existing `.popular(page:)` assertions in `MovieListViewModelTests`.

## View model
`MovieListViewModel` (`ViewModels/MovieListViewModel.swift`):
- Add `private(set) var genres: [Genre] = []`. Add `private(set) var selectedGenre: Genre?`.
- `load()` fetches genres once, in parallel with page 1. A genre failure must not block movies: swallow it and leave `genres` empty so the filter bar stays hidden.
- Add `func select(_ genre: Genre?) async`. It is a no-op if the genre is unchanged. Otherwise it sets `selectedGenre`, resets `movies`, `currentPage`, `totalPages` and `paginationError`, and bumps `generation`. The bump drops in-flight results from the old filter. It then sets `state = .loading` and calls `fetch(page: 1, replacing: true)`.
- `fetch` calls `service.popular(page:genreID: selectedGenre?.id)`.
- `refresh()` keeps the current genre.
- Leave the empty state as `.empty`. The view shows a genre-aware message.

## View
`MovieListView` (`Views/MovieListView.swift`):
- Add a filter control. Two options: a horizontal chip row, or a toolbar `Menu` with a `Picker`. I recommend the toolbar `Menu`. It fits `NavigationStack` and stays out of the `List`, so `.refreshable` and the `.loaded` branch are untouched.
- Menu items: "All" (nil) plus one per `viewModel.genres`. Mark the selected one. Hide the menu while `genres` is empty.
- Calls go through `Task { await viewModel.select(genre) }`.
- The `.empty` branch shows "No \(genre.name) movies" when a genre is selected.
- The `ErrorView` retry keeps working, since `refresh()` preserves the genre.
- `RootView` and `AppDependencies` need no change.

## Tests
Fixtures to add under `Tests/TMDBAppTests/Fixtures`: `genres.json` (add it to the fixture list in `SmokeTests`) and `discover_action_page1.json`.

- **`ModelDecodingTests`**: decode `GenreListResponse` from `genres.json`. Check the count, the first id and the name.
- **`NetworkingTests`**:
  - `genresQuery`: path `/genre/movie/list`, with `api_key` and `language`.
  - `discoverQuery`: path `/discover/movie`, with `with_genres=28`, `sort_by=popularity.desc`, `page=2`.
  - Check that `popularQuery` is unchanged.
- **`ServiceTests`**:
  - `popular(genreID: nil)` sends `.popular`. `popular(genreID: 28)` sends `.discover`.
  - `genres()` sends `.genres` and unwraps the list.
  - The existing client-error propagation test covers `genres()` too.
- **`MovieListViewModelTests`**:
  - `load` fetches genres and page 1, and records `.genres` and `.popular(page: 1, genreID: nil)`.
  - A genre-fetch failure still yields `.loaded` movies, with empty `genres`.
  - `select(genre)` resets the list and calls page 1 with the genre id.
  - Pagination after `select` sends the genre id on page 2.
  - `select(nil)` returns to unfiltered.
  - Selecting the same genre twice makes no second call.
  - A stale response from the previous filter is dropped. Use a delayed mock, as in `duplicateCallsWhileLoadingAreIgnored`.
  - `refresh()` keeps the selected genre.
  - A genre with no results gives `.empty`. A failing filtered load gives `.failed`, and retry succeeds.
- **`AppShellTests`**: preview dependencies return genres, and a filter narrows the preview movies.

## Open questions
1. Should I allow one genre or several? I assumed one.
2. Should the selected genre persist across launches? I assumed no.
3. Do you prefer chips or the toolbar menu? I recommend the menu.