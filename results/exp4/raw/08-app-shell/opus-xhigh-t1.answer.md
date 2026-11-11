The app shell is finished. `swift build` succeeds with no warnings, and `swift test` passes 68 tests in 12 suites (54 existing plus 14 new). The "Executed 0 tests" line in the output is the empty XCTest runner. Nothing is committed, and the fixtures are untouched.

**What's new**
- **`AppDependencies`** (`Sources/TMDBApp/AppDependencies.swift`) has the exact API you specified, plus `makeMovieDetailViewModel(movieID:)`.
  - **Live:** `live()` loads the API key once, with `try?`, so it can't crash. Without a key, the client throws `APIError.missingAPIKey` before touching the network, and screens show an `ErrorView` telling the user to set `TMDB_API_KEY`.
  - **Preview:** `preview` uses a new `PreviewMovieService` with built-in sample data and an `InMemoryFavoritesStore`. Sample image paths are `nil`, because posters would otherwise be fetched from `image.tmdb.org` and previews would go online.
- **`RootView`** has the three tabs, each in its own `NavigationStack`. It keeps the tab view models alive, so a tab's state survives switching tabs. A single `movieDetailDestination(using:)` modifier replaces the three copies of the detail navigation code.
- **`LoadingView`, `EmptyStateView` and `ErrorView`** are built on `ContentUnavailableView`. Every screen uses them, plus a shared `MovieImageView` that replaces two copies of the image loading code.
- **`#Preview`s** cover every screen, the row and the components, including "Missing API key", error and empty variants.

**Duplication and dead code removed**
- The API base URL was hard-coded twice; it now lives only in `TMDBApp.apiBaseURL`.
- `year` and `ratingText` were identical on `Movie` and `MovieDetail`; they're now defined once and shared.
- The Search and Detail view models got their error messages from `MovieListViewModel`. That mapping now lives in its own `ErrorMessage` type.
- Default arguments that quietly built real dependencies are gone: `TMDBMovieService(client: = TMDBClient())` and `FavoritesViewModel(store: = UserDefaults…)`. `AppDependencies` is now the only place real objects are created.
- The search hint hard-coded "2" characters; it now reads `SearchViewModel.minimumQueryLength`.

**Changes you should know about**
- **Pagination retry bug (fixed):** the "Retry" button after a failed page reloaded from page 1. The rows already on screen don't trigger loading again, so the list stayed stuck until you scrolled away and back. It now calls a new `retryNextPage()`, which is tested.
- **Search retry:** the search screen's `ErrorView` now has a "Try Again" button, backed by a new `SearchViewModel.retry()`.
- **Locale bug in my own code:** my first version of the preview search failed a new test on this machine. Under your Turkish locale, `localizedCaseInsensitiveContains` lowercases "I" to "ı", so "incep" didn't match "Inception". It now uses matching that doesn't depend on locale.
- **`TMDBClient` key handling:** the client now requires `configuration` explicitly, and `nil` means "no key". Before, it looked the key up again on every request and ignored any environment you injected, so the missing-key path couldn't be tested reliably.
- **Public entry points:** I made `AppDependencies` (`live()`, `preview`) and `RootView` public, so an app target can host the shell. Everything else stays internal.
- **Placement:** `AppDependencies.swift` sits at the module root next to `TMDBApp.swift`, since it spans all the layers.

I haven't added an `@main App`, because a library target can't contain one. The usage snippet is in the doc comment on `AppDependencies`.