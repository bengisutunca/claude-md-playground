import Foundation

protocol FavoritesStore {
    /// Saved favorites in insertion order.
    func load() -> [Movie]
    func save(_ movies: [Movie])
}

/// Keeps favorites in memory only. For previews.
final class InMemoryFavoritesStore: FavoritesStore {
    private var movies: [Movie]

    init(_ movies: [Movie] = []) {
        self.movies = movies
    }

    func load() -> [Movie] { movies }
    func save(_ movies: [Movie]) { self.movies = movies }
}

struct UserDefaultsFavoritesStore: FavoritesStore, @unchecked Sendable {
    static let defaultKey = "favorites.movies"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = UserDefaultsFavoritesStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    func load() -> [Movie] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Movie].self, from: data)) ?? []
    }

    func save(_ movies: [Movie]) {
        guard let data = try? JSONEncoder().encode(movies) else { return }
        defaults.set(data, forKey: key)
    }
}
