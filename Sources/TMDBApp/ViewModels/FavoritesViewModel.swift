import Foundation
import Observation

@Observable
@MainActor
final class FavoritesViewModel {
    private(set) var favorites: [Movie]

    private let store: FavoritesStore

    init(store: FavoritesStore = UserDefaultsFavoritesStore()) {
        self.store = store
        // Drop duplicates a corrupted store might hold; keep first occurrence.
        var seen = Set<Int>()
        self.favorites = store.load().filter { seen.insert($0.id).inserted }
    }

    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains { $0.id == movie.id }
    }

    /// Adds `movie` at the end, or removes it when already a favorite.
    func toggle(_ movie: Movie) {
        if let index = favorites.firstIndex(where: { $0.id == movie.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(movie)
        }
        store.save(favorites)
    }

    func remove(at offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        store.save(favorites)
    }
}
