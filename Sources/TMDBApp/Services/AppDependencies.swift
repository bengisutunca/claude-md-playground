import Foundation

/// `MovieService` used when no API key is configured. Every call fails with `APIError.missingAPIKey`,
/// so screens show an error instead of crashing.
struct MissingAPIKeyMovieService: MovieService {
    func popular(page: Int) async throws -> PagedResponse<Movie> { throw APIError.missingAPIKey }
    func search(query: String, page: Int) async throws -> PagedResponse<Movie> { throw APIError.missingAPIKey }
    func detail(id: Int) async throws -> MovieDetail { throw APIError.missingAPIKey }
    func credits(id: Int) async throws -> Credits { throw APIError.missingAPIKey }
}

/// Object graph built once and shared by all screens.
@MainActor
struct AppDependencies {
    let service: MovieService
    let favorites: FavoritesViewModel

    /// Real client, service and favorites store. Falls back to `MissingAPIKeyMovieService`
    /// when `loadConfiguration` throws.
    static func make(
        loadConfiguration: () throws -> APIConfiguration = { try APIConfiguration.load() },
        session: URLSession = .shared,
        favoritesStore: FavoritesStore = UserDefaultsFavoritesStore()
    ) -> AppDependencies {
        let service: MovieService
        if let configuration = try? loadConfiguration() {
            service = TMDBMovieService(client: TMDBClient(configuration: configuration, session: session))
        } else {
            service = MissingAPIKeyMovieService()
        }
        return AppDependencies(service: service, favorites: FavoritesViewModel(store: favoritesStore))
    }

    static let live = make()

    /// Offline mock data and an in-memory favorites store. Never touches the network or `UserDefaults`.
    static var preview: AppDependencies {
        AppDependencies(
            service: PreviewMovieService(),
            favorites: FavoritesViewModel(store: InMemoryFavoritesStore(Array(PreviewMovieService.movies.prefix(1)))))
    }

    func makeMovieListViewModel() -> MovieListViewModel { MovieListViewModel(service: service) }
    func makeSearchViewModel() -> SearchViewModel { SearchViewModel(service: service) }
}
