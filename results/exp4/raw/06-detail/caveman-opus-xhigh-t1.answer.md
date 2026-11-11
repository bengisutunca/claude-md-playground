The movie detail screen is in, and you can open it from both the Popular list and Search. `swift build` passes with no warnings and `swift test` passes all 50 tests, including the new ones. Nothing is committed and the fixtures are unchanged. I haven't run the app itself; only the build and tests ran.

**New files**
- `ViewModels/MovieDetailContent.swift`: the required API. Cast is the top 10 by `order` (cast with no `order` go last), directors are crew whose job is "Director", and it has `runtimeText`, `genresText` and `formatRuntime(minutes:)`. I also added `directorsText`.
- `ViewModels/MovieDetailViewModel.swift`: loads detail and credits at the same time with `async let`, and fails if either one fails.
  - Calling `load()` while it's already loading or loaded does nothing; after a failure, calling it again retries.
  - If the load is cancelled (for example, the screen closes), it goes back to idle so it reloads next time.
  - Error messages reuse the existing `MovieListViewModel.message(for:)`, as `SearchViewModel` already does.
- `Views/MovieDetailView.swift`: backdrop with the poster overlapping it, title, tagline, rating, year, runtime, genres, overview, director(s), and a horizontal cast list. There's a Try Again button on failure, and the iOS-only title modifier is wrapped in `#if os(iOS)`.
- `Views/RemoteImage.swift`: one shared image view with a placeholder, now used by the movie row and the detail screen.

**Changes to existing files**
- `MovieListView` and `SearchView` are each wrapped in a `NavigationStack`. Rows link to the detail screen with `NavigationLink(value: movie)` and `navigationDestination(for: Movie.self)`.
- Both list view models gained `detailViewModel(for:)`, so the service stays inside the view models and the views' initialisers didn't change.
- In `MovieListView`, I moved `.task { load() }` onto the stack so opening a detail screen doesn't cancel a list load that's still running.

**Tests**
- `MockMovieService` can now fail just the detail request or just the credits request.
- New tests cover:
  - a successful load with the 27205 fixtures;
  - either request failing (gives `.failed`);
  - retrying after a failure;
  - repeated `load()` calls fetching only once;
  - the top-10 cut, ordering and director filtering, using hand-built credits (the fixture only has 4 cast members);
  - runtime formatting for 148, 120, 60, 61, 59, 45, 1 and 0.

**Decisions for you**
- **Runtime of 0:** `runtimeText` is `nil` when the runtime is missing or 0, because TMDB uses 0 for "unknown", so the screen hides it rather than showing "0m". `formatRuntime(minutes: 0)` still returns "0m" as you specified. This isn't tested, because the tests can't build a `MovieDetail` other than from a fixture.
- **Negative minutes:** `formatRuntime` treats negative values as 0.
- **Navigation stacks:** each screen now has its own `NavigationStack`. If a later app shell (for example a `TabView`) adds another stack around these screens, remove one of the two, because nested stacks don't work properly.