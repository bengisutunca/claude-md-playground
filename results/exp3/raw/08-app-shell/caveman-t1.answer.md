The app shell is finished. `swift build` succeeds and `swift test` passes all 57 tests (three of them new, in `AppDependenciesTests.swift`). I didn't render the `#Preview` blocks, since there's no Xcode canvas here. They only compile in `swift build`.

**What's new**
- **`RootView`** (`Views/RootView.swift`): a `TabView` with Popular, Search and Favorites, each in its own `NavigationStack`. The screens no longer create their own stacks. It also injects the favorites view model into the environment.
- **`AppDependencies`** (`Services/AppDependencies.swift`): matches the required API.
  - `live()` builds the real `TMDBClient`, `TMDBMovieService` and `UserDefaultsFavoritesStore` once.
  - `preview` uses a new offline `PreviewMovieService` with a few built-in movies and an in-memory favorites store (both in `Services/PreviewMovieService.swift`).
- **`LoadingView`, `EmptyStateView`, `ErrorView`** (`Views/StateViews.swift`): used by all four screens in place of the old ad-hoc spinners and text.
- **Missing API key:** nothing is read at startup, so `live()` can't crash. Requests throw `APIError.missingAPIKey`, and the screens show "The TMDB API key is missing." in an `ErrorView`. The tests only check that `live()` constructs without crashing and that the error message text is right. They don't make a request without a key, because the key is read from the real environment.
- **`#Preview` blocks:** one for each screen plus `RootView`, all using `AppDependencies.preview`.

**Duplication and dead code removed**
- The three identical "push the movie detail" destinations are now one `movieDetailDestination(service:)` modifier.
- The poster placeholder image code that appeared in two views is now a shared `PosterImage` view.
- The error-to-message mapping lived in `MovieListViewModel` but was called by the other view models. It is now `APIError.message(for:)`.
- `APIConfiguration` reused its own copy of the API base URL; it now uses `TMDBApp.apiBaseURL`.
- I didn't find other unused code: the remaining candidates (`canLoadMore`, `waitForSearch`, `releaseYear`, `ImageURLBuilder.Size.original`) are all used by tests or views.

I didn't touch the fixtures and haven't committed anything.