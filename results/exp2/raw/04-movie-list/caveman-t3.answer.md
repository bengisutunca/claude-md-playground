Popular movies screen done. `swift build` succeeds and `swift test` passes all 40 tests, including the 10 new view model tests. I didn't run the SwiftUI views, so they're compile-checked only.

**What I added**
- `ViewState` in `ViewModels/ViewState.swift`.
- `MovieListViewModel` in `ViewModels/MovieListViewModel.swift`, with the required API.
- `MovieListView` and `MovieRowView` in `Views/`. The row has an `AsyncImage` poster with a placeholder, plus title, year and rating. Pull to refresh uses `.refreshable`, and `.listStyle(.plain)` is wrapped in `#if os(iOS)`.
- Tests in `MovieListViewModelTests.swift`. They cover first load, pagination, end of pages, errors and refresh reset.

**Behavior the spec didn't cover**
- `load()` does nothing once movies are loaded, so `.task` re-firing won't reload.
- A refresh or next-page failure keeps the existing list and sets `errorMessage`. Only an empty list goes to `.failed`.
- Error text is user-facing. Network failures say "Can't reach the server. Check your connection and try again." HTTP errors show the server's message when there is one.

I also deleted the two `.gitkeep` files in `ViewModels/` and `Views/`, since those folders now have real files. Nothing is committed, and I didn't touch the fixtures.