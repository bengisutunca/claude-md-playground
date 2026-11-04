# Plan: genre filter on the Popular tab

**What the user gets:** a genre menu in the Popular tab's toolbar. It offers "All Genres" plus the genres TMDB returns. Picking a genre reloads the list from page 1 with only that genre. Paging and pull-to-refresh keep using the chosen genre. "All Genres" goes back to today's `/movie/popular` list. If the genre list fails to load, the menu is hidden and the movie list still works.

**Left out on purpose:** choosing more than one genre, remembering the choice across launches, and genre filters on Search or Favorites.

The plan reuses what already exists. `Genre` is already decodable, `PagedResponse<Movie>` already fits the discover response, and the `generation` counter in `MovieListViewModel` already drops results from requests that have been superseded.

## Models
- **`Genre`** (`Models/Genre.swift`): no change. It's already `Decodable` and `Hashable`, which is enough for a picker.
- **New `GenreListResponse { let genres: [Genre] }`**: the wrapper `/genre/movie/list` returns. Put it in `Genre.swift`, next to the type it wraps.
- **Discover results** decode as the existing `PagedResponse<Movie>`, so no new type is needed.

## Networking (`Endpoint.swift`)
- **Add `case genres`**:
  - path `/genre/movie/list`
  - no extra query items; `api_key` and `language` are already added for every request.
- **Add `case discover(genreID: Int, page: Int)`**:
  - path `/discover/movie`
  - query items `with_genres=<id>`, `sort_by=popularity.desc` and `page`.
  - `sort_by` keeps the order matching the "Popular" meaning of the tab.
- `HTTPClient` and `TMDBClient` don't change.

## Service
- **`MovieService` protocol**:
  - Change `popular(page:)` to `popular(page: Int, genreID: Int?)`.
  - Add `genres() async throws -> [Genre]`.
- **`TMDBMovieService`**:
  - `genreID == nil` → `.popular(page:)`; otherwise → `.discover(genreID:page:)`.
  - Choosing the endpoint is a TMDB detail, so it belongs here rather than in the view model.
  - `genres()` sends `.genres` and returns `GenreListResponse.genres`.
  - Give the concrete method a default (`genreID: Int? = nil`) so existing call sites still compile.
- **`PreviewMovieService`**:
  - Return a fixed genre list.
  - Give the sample `movies` some `genreIDs`.
  - Filter by `genreIDs.contains(genreID)` so previews show the filter working.

## View model (`MovieListViewModel`)
- **New state:**
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenre: Genre?`
- **`load()`**:
  - Fetch genres alongside page 1 (`async let`), and only if `genres` is empty.
  - A genre failure leaves `genres` empty (menu hidden). It never sets `state = .failed`, because the filter is optional.
- **New `selectGenre(_ genre: Genre?) async`**:
  - Return early if `genre == selectedGenre`.
  - Otherwise set `selectedGenre`, then restart: `generation += 1`, clear `movies`, `currentPage = 0`, `totalPages = 1`, `paginationError = nil`, `state = .loading`, then `fetch(page: 1)`.
  - It clears the list right away, unlike `refresh()`, which keeps the old movies until new ones arrive. Otherwise movies from the old genre would sit under the new genre's label.
  - Move the shared reset into one private `restart(clearing:)` that both `refresh()` and `selectGenre` use, rather than copying the reset code.
- **`fetch`**: call `service.popular(page:genreID: selectedGenre?.id)`. Pagination and refresh then follow the current genre without extra code.
- **What must stay true:** a late response for an earlier genre is dropped by the existing `token == generation` check. Don't add a second guard for it.

## View (`MovieListView`)
- **Toolbar menu:**
  - Add `.toolbar { ToolbarItem { Menu { Picker("Genre", selection: …) } } }` with an "All Genres" option (`nil`) followed by `viewModel.genres`.
  - Show it only when `genres` isn't empty.
  - The picker's setter runs `Task { await viewModel.selectGenre($0) }`.
- **Why the toolbar and not inside the `List`:**
  - The `.empty` and `.failed` states replace the `List`, so a filter inside it would disappear.
  - The user could then get stuck on an empty genre with no way back to "All Genres".
  - `Picker` and `Menu` also come with VoiceOver labels.
- **Empty state:** when a genre is selected, use a message like "No movies in Action" in `EmptyStateView`.

## Tests
**Fixtures:** add `genre_movie_list.json` (a few genres) and `discover_genre_28_page1.json`. You can reuse the popular fixtures for discover in the mock if you want fewer files.

- **`NetworkingTests`**:
  - `.genres` builds `/genre/movie/list` with `api_key` and `language`.
  - `.discover(genreID: 28, page: 2)` builds `/discover/movie` with `with_genres=28`, `sort_by=popularity.desc` and `page=2`.
- **`ModelDecodingTests`**: `GenreListResponse` decodes the genre fixture (count, first id and name).
- **`TMDBMovieServiceTests`** (`ServiceTests.swift`, existing `MockHTTPClient`):
  - `popular(page: 1, genreID: nil)` records `.popular(page: 1)`.
  - `popular(page: 1, genreID: 28)` records `.discover(genreID: 28, page: 1)`.
  - `genres()` records `.genres` and returns the decoded list.
- **`MockMovieService` updates:**
  - Change `Call.popular` to `popular(page: Int, genreID: Int? = nil)`. The default keeps the existing `.popular(page: 1)` assertions valid.
  - Add `Call.genres` and a separate `genresError`, so genre failures can be tested on their own.
  - Add an optional gate (a continuation) on `popular`, so a test can hold one request open.
- **`MovieListViewModelTests`**:
  1. `load()` fills `genres` and calls `.genres` once. A second `load()` doesn't fetch again.
  2. A genre failure: `state` is still `.loaded`, `genres` is empty.
  3. `selectGenre(action)`: the list resets and the calls end with `.popular(page: 1, genreID: 28)`.
  4. Paging after a selection requests `page: 2, genreID: 28`. `refresh()` keeps the genre.
  5. `selectGenre(nil)` goes back to `genreID: nil`. Selecting the current genre makes no call.
  6. Stale result: hold the genre-A request at the gate, select genre B, release A. The state shows B's results.

**Proof to run:** `swift test`, after updating the existing `MovieListViewModelTests` and `ServiceTests` call sites to the new signature.

**One choice to confirm:** I kept `/movie/popular` for "All Genres" so the current tab behaves exactly as it does now. Routing everything through `/discover/movie` would be one code path, but its ranking can differ a little from `/movie/popular`.