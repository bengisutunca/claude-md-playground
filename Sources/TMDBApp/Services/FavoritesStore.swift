import Foundation

/// Persistence for favorite movies. Order is insertion order; no duplicates by `Movie.id`.
protocol FavoritesStore {
    func load() -> [Movie]
    func save(_ movies: [Movie])
}

struct UserDefaultsFavoritesStore: FavoritesStore {
    static let defaultKey = "favorites.movies"

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = UserDefaultsFavoritesStore.defaultKey) {
        self.defaults = defaults
        self.key = key
    }

    func load() -> [Movie] {
        guard let data = defaults.data(forKey: key),
              let movies = try? JSONDecoder.tmdb.decode([Movie].self, from: data) else { return [] }
        return Self.deduplicated(movies)
    }

    func save(_ movies: [Movie]) {
        guard let data = try? JSONEncoder().encode(Self.deduplicated(movies)) else { return }
        defaults.set(data, forKey: key)
    }

    private static func deduplicated(_ movies: [Movie]) -> [Movie] {
        var seen = Set<Int>()
        return movies.filter { seen.insert($0.id).inserted }
    }
}
