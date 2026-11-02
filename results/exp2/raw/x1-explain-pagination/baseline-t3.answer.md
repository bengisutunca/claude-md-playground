`MovieListViewModel` is in `Sources/TMDBApp/ViewModels/MovieListViewModel.swift`. It is `@MainActor` and `@Observable`, and it fetches through an injected `MovieService`, calling `service.popular(page:)`.

## State it holds
- `state: ViewState<[Movie]>` is the public state. Its cases are `.idle`, `.loading`, `.loaded`, `.empty` and `.failed(message)`.
- `paginationError` and `isLoadingNextPage` are separate flags for page 2 and later, so the list stays visible during pagination.
- Private bookkeeping: `movies`, `currentPage` (starts at 0), `totalPages` (starts at 1), `isFetching`, and `generation`.
- `canLoadMore` is `currentPage < totalPages`.

## First load
- `MovieListView` calls `viewModel.load()` from `.task`.
- `load()` returns immediately unless `!isFetching && currentPage == 0`. Repeated `.task` firings, such as re-appearing views, therefore don't refetch.
- Otherwise it sets `state = .loading` and calls `fetch(page: 1)`.
- On success, `fetch` appends the results, stores `currentPage` and `totalPages` from the response, and sets `.loaded(movies)`, or `.empty` if there are no movies.

## Next page
- Each row in `MovieListView` has `.task { await viewModel.loadNextPageIfNeeded(currentItem: movie) }`.
- The guard requires all of these:
  - nothing is in flight (`!isFetching`);
  - `canLoadMore` is true;
  - the first page has loaded (`currentPage > 0`);
  - the row's movie is found in `movies`;
  - that row's index is within the last 3 items (`index >= movies.count - 3`).
- If the guard passes, it sets `isLoadingNextPage = true`, clears `paginationError`, and fetches `currentPage + 1`.
- The view's footer shows a spinner while `isLoadingNextPage` is true. If `paginationError` is set, it shows an error with a retry.

## Refresh
- `refresh()` is called from `.refreshable` and from both retry buttons: the full-screen `ErrorView` and the pagination error footer.
- It increments `generation`, clears `isLoadingNextPage` and `paginationError`, and sets `state = .loading` only if no movies are loaded. Otherwise the existing list stays on screen during the pull-to-refresh.
- It then calls `fetch(page: 1, replacing: true)`. The old movies are cleared only after the new response arrives, which avoids a flash of an empty list.
- `refresh()` has no `isFetching` guard, so it always starts a new request.

## Duplicate and stale requests
- **Duplicate requests:** `isFetching` blocks a second `load()` or `loadNextPageIfNeeded` while a request is running. Rows that appear repeatedly near the end therefore can't trigger the same page twice.
- **Stale requests:** `fetch` captures `let token = generation` at the start.
  - After the `await`, `guard token == generation` drops the result if a refresh happened in the meantime. That covers a slow page-2 response arriving after a refresh.
  - The `defer` resets `isFetching` and `isLoadingNextPage` only when the token still matches. The newer refresh request owns those flags and clears them when it finishes.
- **Duplicate movies:** on append, results are filtered against a `Set` of known IDs, so a movie repeated across pages (the popular list can shift between requests) is not added twice.
- **Cancellation:** a `CancellationError` returns silently, with no state change and no error shown. This happens when SwiftUI cancels a `.task` as its view goes away. The `defer` still resets `isFetching` if the token matches.

## Errors
- Errors are turned into text with `error.userMessage`.
- Stale errors are ignored: the `catch` also checks the token.
- If no movies are loaded (first load, or a refresh from an empty state), `state = .failed(message)`. The view shows the full-screen `ErrorView`, and its retry calls `refresh()`.
- If movies are already loaded, only `paginationError` is set. The list stays visible and the footer offers a retry.
- The footer retry calls `refresh()`, which reloads from page 1 rather than retrying only the failed page.
- A failed refresh while movies are on screen also lands in `paginationError`, not `.failed`. This is because the `movies.isEmpty` check happens before `movies = []` runs, and `movies` is only cleared on success.