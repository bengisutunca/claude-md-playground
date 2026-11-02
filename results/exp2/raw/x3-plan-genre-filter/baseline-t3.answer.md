# Plan: genre filter on the Popular tab

I read the existing code and changed nothing.

## Key design decision

`/movie/popular` doesn't accept `with_genres`, so the filter needs a different endpoint when a genre is selected. I would have the filter control which endpoint the list uses:
- **No genre selected:** keep `/movie/popular`, so default behavior and ordering stay the same.
- **Genre selected:** call `/discover/movie` with `with_genres=<id>` and `sort_by=popularity.desc`. That keeps the list ordered by popularity, like the Popular tab.

Both endpoints return the same `PagedResponse<Movie>` shape, so the pagination code can stay as it is.

## Per layer

**Models**
- `Models/Genre.swift` already has `Genre` (`id`, `name`). It is `Decodable` and `Hashable`, so it can be used as a selection value.
- Add `GenreListResponse: Decodable, Sendable` with `genres: [Genre]`. `/genre/movie/list` returns `{"genres": [...]}`, not a paged response.
- `Movie` already has `genreIDs`. I would not use it for client-side filtering, because the server should do the filtering so pagination stays correct.

**Networking** (`Networking/Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. It needs no extra query items.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. It adds `with_genres`, `sort_by=popularity.desc` and `page` to the query. Add the new cases to the `switch` in `queryItems`.
- If you want multi-select later, `with_genres` takes comma-separated IDs for AND and pipe-separated IDs for OR. I would keep a single genre for now.

**Service**
- `Services/MovieService.swift`: add `func genres() async throws -> [Genre]` and `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`. A single `popular(page:genreID:)` would be an alternative, but separate methods keep each one mapped to one endpoint.
- `Services/TMDBMovieService.swift`: implement both with `client.send`. `genres()` decodes `GenreListResponse` and returns `.genres`.
- `Services/PreviewMovieService.swift`: add static sample genres. `discover` should filter `Self.movies` by `genreIDs`, so the sample movies need genre IDs.
- `Tests/.../MockMovieService.swift` has to conform, so it needs a `Call.genres` case and a `Call.discover(genreID:page:)` case. It also needs new fixtures.

**View model** (`ViewModels/MovieListViewModel.swift`)
- Add `private(set) var genres: [Genre] = []` and `private(set) var selectedGenre: Genre?`. A separate small `genresState` or `genresError` would keep a failed genre list from blocking the movie list.
- `loadGenres()` runs once, ideally from `load()` alongside the first page. If it fails, the movie list still works and the filter is just hidden or disabled.
- `selectGenre(_ genre: Genre?)` does nothing if the value is unchanged. Otherwise it sets `selectedGenre`, resets paging, and calls `refresh()`. The existing `generation` counter already drops stale responses, so quickly switching genres is safe. `refresh()` shows `.loading` only when `movies` is empty, so `selectGenre` must clear `movies` first. Otherwise the old genre's list stays visible during the load.
- `fetch(page:)` picks `service.discover(genreID:page:)` when `selectedGenre` is set, and `service.popular(page:)` otherwise.
- An empty result for a genre goes to the existing `.empty` state. The empty-state view text could name the genre.

**View** (`Views/MovieListView.swift`)
- Add a `.toolbar` with a `Menu` (a filter icon) listing "All" plus each genre, with a checkmark on the selected one. A horizontally scrolling chip row above the list is the alternative. The menu is simpler and works inside the existing `NavigationStack`.
- The menu calls `Task { await viewModel.selectGenre(...) }`.
- The filter must stay visible in the `.empty` and `.failed` states, so the user can change genre from there. That means the toolbar belongs on `body`, not inside `content`.
- Optionally show the selected genre in the navigation title, for example "Popular · Action".
- `Views/RootView.swift` and `AppDependencies.swift` need no changes, because the service is already injected.

## Tests

- **`NetworkingTests`**
  - `genresQuery`: path is `/3/genre/movie/list`, query is `api_key` and `language` only.
  - `discoverQuery`: path is `/3/discover/movie`, with `with_genres`, `sort_by` and `page`.
- **`ModelDecodingTests`**: `GenreListResponse` decodes from a new `genre_list.json` fixture.
- **`ServiceTests`**
  - `TMDBMovieService.genres()` requests `.genres` and decodes.
  - `discover` requests `.discover(genreID:page:)`.
  - Errors propagate.
  - The `MockMovieService` records the new calls.
- **`MovieListViewModelTests`**
  - Loading the genres populates `genres`.
  - A genre-load failure doesn't break the movie list.
  - `selectGenre` calls `discover` with page 1, replaces the movies, and resets `canLoadMore`.
  - Pagination under a genre calls `discover(page: 2)`.
  - Selecting `nil` returns to `popular`.
  - Reselecting the same genre makes no extra call.
  - An empty result gives `.empty`.
  - A discover error gives `.failed` and a retry works.
  - A stale response is dropped after a fast A→B switch.
- **`AppShellTests`**: only a small update if it constructs a `MockMovieService`. I'd check that file once the change is made.
- **New fixtures** in `Tests/TMDBAppTests/Fixtures`: `genre_list.json` and `discover_action_page1.json`.

## Suggested order

1. Models and `Endpoint`, with their tests.
2. The `MovieService` protocol, `TMDBMovieService` and the mocks.
3. The view model and its tests.
4. The view.

Each step builds and tests on its own. One open question is whether the genre list should be cached for the session. I'd keep it in the view model for now and skip persistence.