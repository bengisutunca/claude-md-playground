Favorites are in. `swift build` succeeds, and `swift test` passes all 54 tests, including 5 new ones in `Tests/TMDBAppTests/FavoritesTests.swift`. I haven't launched the app, so the heart button, the favorites list and swipe-to-delete are untested.

**What changed**
- **Store and view model:** `FavoritesStore`, `UserDefaultsFavoritesStore` and `FavoritesViewModel` use the exact names and signatures you listed. The view model loads in `init` and saves after every change. `toggle` appends new favorites at the end and removes existing ones by `id`, so there are no duplicates.
- **`FavoritesView`:** it has an empty state and swipe-to-delete.
- **Heart button:** it sits in the `MovieDetailView` toolbar and reads the shared `FavoritesViewModel` from the SwiftUI environment.
- **`Movie` is now `Codable`:** it writes `releaseDate` back as the `"yyyy-MM-dd"` string, and I added `TMDBDate.string(from:)` for that. The store decodes with `JSONDecoder.tmdb`, so a saved movie round-trips equal.

**Things to know**
- **`MovieDetailView` signature:** it now takes `movie: Movie`, because the detail model alone doesn't give the toggle a `Movie`. I updated the call sites in `MovieListView` and `SearchView`.
- **Nothing injects the view model yet:** the package has no `@main` app or tab root, so I didn't add a `.environment(...)` call. Whatever hosts the app has to inject one `FavoritesViewModel`, or `MovieDetailView` and `FavoritesView` will crash on first use.
- **No navigation from favorites:** rows in `FavoritesView` don't open the detail screen, since that would need the movie service. I left it out.