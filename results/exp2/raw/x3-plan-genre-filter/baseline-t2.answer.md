# Plan: genre filter on the Popular tab

I read the code but changed no files. The current shape is: `Endpoint` (enum) → `HTTPClient`/`TMDBClient` → `MovieService` protocol, implemented by `TMDBMovieService` and `PreviewMovieService` → `MovieListViewModel` → `MovieListView`. `Genre` already exists in `Models/Genre.swift` as a `Decodable` struct with `id` and `name`, and `MovieDetail` uses it.

**Design decision:** with no genre selected, keep calling `/movie/popular`. With a genre selected, call `/discover/movie` with `sort_by=popularity.desc` and `with_genres=<id>`. That keeps the unfiltered path untouched and its tests valid. The discover endpoint is the only one that supports genre filtering, and sorting by popularity keeps the "Popular" meaning.

## 1. Models
- **`Genre`**: it only conforms to `Decodable` today. Add `Encodable` or leave it, since encoding isn't needed.
- **New `GenreListResponse`** (in `Models/Genre.swift` or its own file): `struct GenreListResponse: Decodable, Sendable { let genres: [Genre] }`, because `/genre/movie/list` returns `{"genres": [...]}`.
- `PagedResponse<Movie>` is reused as is, since discover returns the same paged shape.

## 2. Networking (`Networking/Endpoint.swift`)
- Add `case genres` with path `/genre/movie/list`. It needs no extra query items beyond `api_key` and `language`, so add it to the `break` case in `queryItems`.
- Add `case discover(genreID: Int, page: Int)` with path `/discover/movie`. Its query items are `page`, `with_genres=<id>` and `sort_by=popularity.desc`.
- Both switches in `Endpoint` are exhaustive, so the compiler will point out every spot that needs updating.
- `HTTPClient` and `TMDBClient` need no changes.
- Optional: make `discover` take `genreIDs: [Int]`, joined with `,` for AND or `|` for OR. A single-select UI only needs one ID, so I'd start with `Int` and not over-build.

## 3. Service
- **`MovieService`** gets two new methods:
  - `func genres() async throws -> [Genre]`
  - `func discover(genreID: Int, page: Int) async throws -> PagedResponse<Movie>`
- **`TMDBMovieService`**: implement both through `client.send`. `genres()` decodes `GenreListResponse` and returns `.genres`.
- **`PreviewMovieService`**: add static sample genres. Give the sample `Movie`s genre IDs or filter by hand so the preview shows filtering. `Movie` has no `genreIDs` field today, so either add an optional `genreIds` (`genre_ids` in the JSON, defaulting to `[]`) or have the preview just return the full list.
- **`MockMovieService`** (tests): add `Call.genres` and `Call.discover(genreID:page:)`, and return new fixtures.
- **`AppDependencies`** needs no changes, because `makeMovieListViewModel()` already passes `movieService`.

## 4. View model (`MovieListViewModel`)
- New state:
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenre: Genre?`
  - Optionally `genresError`. A failed genre load should not break the movie list. It should just hide the filter or show a retry chip.
- `load()` also fetches genres, without blocking the movie fetch. Run them concurrently with `async let`, or start the genre fetch in a child task. A genre failure is swallowed or recorded in `genresError`.
- New `func select(genre: Genre?) async`:
  - Return early if the genre is unchanged.
  - Set `selectedGenre`.
  - Reset pagination: `currentPage = 0`, `totalPages = 1`, `movies = []`, `paginationError = nil`, `isLoadingNextPage = false`.
  - Set `state = .loading`.
  - Increment `generation` so in-flight responses for the old filter are dropped. The existing `token == generation` check already handles this.
  - Call `fetch(page: 1, replacing: true)`.
- `fetch(page:replacing:)`: replace the `service.popular(page:)` call with a helper that picks the endpoint:
  ```swift
  if let g = selectedGenre { try await service.discover(genreID: g.id, page: page) }
  else { try await service.popular(page: page) }
  ```
- `refresh()` keeps the selected genre, so pull-to-refresh reloads the filtered list.
- **Pitfall:** `load()` guards on `!isFetching`. `select` must bypass or reset `isFetching`, because the generation bump makes the old fetch's `defer` skip clearing it. Check this carefully. `refresh()` already has the same pattern, so copy how it handles it.
- **Empty state:** `.empty` is already produced when a genre has no results. Consider a more specific message in the view.

## 5. View (`MovieListView`)
- Add a horizontal chip bar above the list: an "All" chip plus one chip per `viewModel.genres`. Tapping a chip calls `Task { await viewModel.select(genre:) }`, and the selected chip is highlighted. Put it in a `ScrollView(.horizontal)` pinned with `.safeAreaInset(edge: .top)`.
- Alternative: a toolbar `Menu` or `Picker` with a funnel icon. It's less visible but takes less space. I'd go with chips.
- The chip bar must stay visible across `.loading`, `.empty` and `.failed`, so the user can switch genre after an error or an empty result. Place it outside the `switch` in `content`.
- Update `EmptyStateView` to say "No \(genre) movies" when a genre is selected.
- Add accessibility labels and `.isSelected` traits on the chips.
- Update `#Preview` so it uses `PreviewMovieService` with genres.

## 6. Tests (Swift Testing, matching the existing style)
- **Fixtures** (in the existing fixtures folder used by `Fixture.data`): `genres.json` and `discover_page1.json`, and maybe `discover_empty.json`.
- **`ModelDecodingTests`**: decode `GenreListResponse`, and check the count and one name and ID.
- **`NetworkingTests`**, using the existing `parts(_:)` helper:
  - `genresQuery`: path `/3/genre/movie/list`, items `api_key` and `language`.
  - `discoverQuery`: path `/3/discover/movie`, items include `with_genres`, `sort_by=popularity.desc` and `page`.
- **`ServiceTests`**: `TMDBMovieService.genres()` and `.discover(...)` hit the right endpoints and decode correctly. Follow how the existing tests there stub the client.
- **`MovieListViewModelTests`**, using `MockMovieService`:
  - `load()` fetches both genres and popular movies.
  - A genre-fetch failure still leaves the movie list `.loaded`.
  - `select(genre:)` calls `discover(genreID:page:1)` and replaces the movies.
  - Selecting `nil` returns to `popular`.
  - Pagination while filtered calls `discover` with page 2.
  - Switching genre mid-flight drops the stale response (use the existing generation-style test pattern).
  - A genre with no results gives `.empty`.
  - A discover error gives `.failed`, and a later `select(nil)` recovers.
  - `refresh()` keeps the selected genre.
  - Selecting the same genre twice makes no extra request.
- **`AppShellTests`**: adjust only if it relies on the exact `Call` list. It builds `MovieListViewModel` with a failing mock, so it should keep passing.
- **Existing tests:** any `MovieService` conformer must gain the new methods or the test target won't compile. Search for other conformers before starting.

## Suggested order
1. Models.
2. `Endpoint`, plus its tests.
3. Protocol, `TMDBMovieService`, `PreviewMovieService` and `MockMovieService`, plus service tests.
4. View model, plus its tests.
5. View.
6. Run `swift test`.

## Open questions
- Single-select (what I assumed) or multi-select genres? Multi-select needs AND/OR semantics for `with_genres`.
- Should the selected genre persist across launches? It's session-only in this plan.