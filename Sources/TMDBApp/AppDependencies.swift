import Foundation

/// Composition root: builds the shared client, service and favorites once and hands them to screens.
@MainActor
final class AppDependencies {
    let movieService: any MovieService
    let favorites: FavoritesViewModel

    init(movieService: any MovieService, favoritesStore: any FavoritesStore) {
        self.movieService = movieService
        self.favorites = FavoritesViewModel(store: favoritesStore)
    }

    /// Real TMDB networking and `UserDefaults` persistence. The API key is resolved on first
    /// request, so a missing key surfaces as an error state rather than a crash.
    static func live() -> AppDependencies {
        AppDependencies(movieService: TMDBMovieService(client: TMDBClient()),
                        favoritesStore: UserDefaultsFavoritesStore())
    }

    /// Mock data and in-memory persistence for SwiftUI previews.
    static var preview: AppDependencies {
        AppDependencies(movieService: PreviewMovieService(),
                        favoritesStore: InMemoryFavoritesStore(Array(PreviewMovieService.movies.prefix(2))))
    }

    func makeMovieListViewModel() -> MovieListViewModel { MovieListViewModel(service: movieService) }
    func makeSearchViewModel() -> SearchViewModel { SearchViewModel(service: movieService) }
}
