import Foundation
import Observation

@MainActor
@Observable
final class FavoritesViewModel {
    private(set) var favorites: [Movie]

    @ObservationIgnored private let store: any FavoritesStore

    init(store: any FavoritesStore = UserDefaultsFavoritesStore()) {
        self.store = store
        self.favorites = store.load()
    }

    func isFavorite(_ movie: Movie) -> Bool {
        favorites.contains { $0.id == movie.id }
    }

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
