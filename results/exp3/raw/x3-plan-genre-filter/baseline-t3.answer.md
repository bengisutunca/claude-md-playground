# Plan: genre filter on the Popular tab

I read `Endpoint`, `MovieService`, `TMDBMovieService`, `PreviewMovieService`, `MovieListViewModel`, `MovieListView` and `MockMovieService`. Nothing was modified.

**Design choices**
- **Single-select genre.** A nil genre means "All" and keeps using `/movie/popular`. A selected genre uses `/discover/movie?with_genres=<id>&sort_by=popularity.desc`. The ordering is close to Popular but not identical, which is why I keep both endpoints instead of always using discover.
- **Server-side filtering.** `Movie` has no genre ids, so the app can't filter locally. Each genre change needs a fresh fetch from page 1.
- **Genre list is non-critical.** If `/genre/movie/list` fails, the chips are hidden and the list still works.

## 1. Models
- **`Models/Genre.swift`**: `Genre` already exists with `id` and `name`, so it needs no change.
- **New `GenreListResponse`** (put it in `Genre.swift`): `struct GenreListResponse: Decodable, Sendable { let genres: [Genre] }`. The endpoint returns `{"genres":[…]}` and isn't paged, so `PagedResponse` doesn't fit.

## 2. Networking (`Networking/Endpoint.swift`)
- Add `case discover(genreID: Int, page: Int)` and `case genreList`.
- Paths: `/discover/movie` and `/genre/movie/list`.
- In `queryItems(apiKey:)`:
  - `.discover` adds `with_genres=<id>`, `sort_by=popularity.desc` and `page`.
  - `.genreList` adds nothing beyond the default `api_key` and `language`.
- Update the existing `switch`, which currently groups `.movieDetail, .credits` as no extras. `.genreList` joins that group.
- `HTTPClient` and `APIConfiguration` stay unchanged.

## 3. Service
- **`Services/MovieService.swift`**: add `func genres() async throws -> [Genre]`. Change `popular(page:)` to `popular(page: Int, genreID: Int?)`. This keeps one entry point for the list and avoids a parallel `discover` method.
  - The alternative is a separate `discover(genreID:page:)` method. It leaves existing call sites and tests untouched, but the view model then has to branch. I prefer the optional parameter, and I'd give it a default through a protocol extension so existing `popular(page:)` call sites still compile.
- **`Services/TMDBMovieService.swift`**:
  - `popular` sends `.discover` when `genreID` is non-nil and `.popular` otherwise.
  - `genres()` sends `.genreList` as `GenreListResponse` and returns `.genres`.
- **`Services/PreviewMovieService.swift`**:
  - Return a static genre list that includes Action and Science Fiction, matching `detailJSON`.
  - The preview movies have no genre data, so for a non-nil `genreID` return a subset (for example, the first two movies).
- **`AppDependencies`** needs no change.

## 4. View model (`ViewModels/MovieListViewModel.swift`)
- New state:
  - `private(set) var genres: [Genre] = []`
  - `private(set) var selectedGenreID: Int?`
- `load()` also fires `loadGenres()` and ignores its errors, so a genre failure never blocks movies.
- Add `func selectGenre(_ id: Int?) async`:
  - Return if `id == selectedGenreID`.
  - Set `selectedGenreID`, then call the existing `refresh()` logic.
  - Reset `currentPage` to 0 and `totalPages` to 1.
  - Clear `movies`, set `state = .loading`, and clear `paginationError`.
  - Clearing `movies` matters because `refresh()` only shows `.loading` when `movies.isEmpty`. Without it, the old genre's results would sit on screen during the switch.
- `fetch` passes `genreID: selectedGenreID` to `service.popular`.
- The existing `generation` token already drops stale responses, so a quick A→B genre switch can't show A's results. `refresh()` bumps it, and `selectGenre` goes through that path.
- Pagination continues to use `selectedGenreID`, so page 2 stays within the chosen genre.
- `.empty` still applies when a genre has no results. The view can show a genre-specific message.

## 5. View (`Views/MovieListView.swift`)
- Add a horizontal `ScrollView` of chips above the list: an "All" chip plus one per `viewModel.genres`.
  - Highlight the chip matching `selectedGenreID`.
  - Tapping calls `Task { await viewModel.selectGenre(id) }`.
  - Place it in `.safeAreaInset(edge: .top)` or a `VStack` around `content`, so it stays visible in the loading, empty and failed states. Putting it inside the `.loaded` `List` would make it disappear when a genre returns nothing, leaving no way to switch back.
  - Hide it while `genres.isEmpty`.
- Add accessibility labels and the `.isSelected` trait on the chips.
- The empty state text could read "No movies in this genre".
- `RootView` and the `#Preview` need no change, because `PreviewMovieService` now supplies genres.

## 6. Tests
Fixtures go in `Tests/TMDBAppTests/Fixtures/` (the Package copies the folder). Add `genre_list.json` (a few genres) and `discover_action_page1.json` (a short results page).

- **`ModelDecodingTests`**: decode `GenreListResponse` from `genre_list.json` and check the count and a name.
- **`NetworkingTests`**:
  - `.discover(genreID: 28, page: 2)` gives path `/discover/movie` and query items `with_genres=28`, `page=2` and `sort_by=popularity.desc`, plus `api_key` and `language`.
  - `.genreList` gives path `/genre/movie/list`.
- **`ServiceTests`**, using the `MockURLProtocol` setup these tests already use:
  - `popular(page:genreID: nil)` hits `/movie/popular`.
  - `popular(page:genreID: 28)` hits `/discover/movie` with `with_genres=28`.
  - `genres()` decodes the list.
  - An error on `genres()` propagates.
- **`MockMovieService`**:
  - Add `Call.genres` and change `Call.popular` to `popular(page:genreID:)`.
  - Add `genres()` returning the `genre_list` fixture.
  - Serve a different fixture when `genreID != nil`, so tests can tell the lists apart.
  - Existing `Call.popular(page:)` assertions in `MovieListViewModelTests` and `ServiceTests.MockMovieServiceTests` will need updating.
- **`MovieListViewModelTests`**:
  - `load()` populates `genres` and `selectedGenreID` is nil.
  - `selectGenre(28)` calls the service with `genreID: 28` and page 1.
  - `selectGenre(28)` replaces the movies, and `selectGenre(nil)` restores the unfiltered list.
  - Pagination after selecting a genre requests page 2 with the same genre.
  - Selecting the same genre again makes no extra call.
  - A failing `genres()` still leaves the movies `.loaded`, with `genres` empty.
  - A genre with an empty result gives `.empty`, and selecting another genre recovers.
  - Stale response: with a delayed mock, select A then B quickly, and only B's results appear. This may need a delay or continuation option on the mock.
- **`AppShellTests` or `SmokeTests`**: confirm `AppDependencies.preview` still builds a `MovieListViewModel` that loads genres.

## Suggested order
1. Models and `Endpoint`, with their tests.
2. Service protocol, `TMDBMovieService`, `PreviewMovieService`, and `MockMovieService` with its fixtures.
3. View model and its tests.
4. View.
5. Run `swift test`, then check the preview by eye.

## Open questions
- Should multiple genres be selectable? TMDB uses a comma for AND and a pipe for OR in `with_genres`. If so, `genreID: Int?` becomes `Set<Int>` plus a mode, which is a bigger UI change. I'd ship single-select first.
- Should the selected genre persist across launches? I assumed it doesn't.