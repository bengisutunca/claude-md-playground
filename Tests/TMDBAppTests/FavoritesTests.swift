import Foundation
import Testing
@testable import TMDBApp

@MainActor
struct FavoritesTests {
    private func withSuite(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "FavoritesTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    private func movies() throws -> [Movie] {
        try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: Fixture.data("popular_page1")).results
    }

    private func makeVM(_ defaults: UserDefaults) -> FavoritesViewModel {
        FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
    }

    @Test func toggleOnOff() throws {
        let movie = try movies()[0]
        withSuite { defaults in
            let vm = makeVM(defaults)
            #expect(!vm.isFavorite(movie))
            vm.toggle(movie)
            #expect(vm.isFavorite(movie))
            vm.toggle(movie)
            #expect(!vm.isFavorite(movie))
            #expect(vm.favorites.isEmpty)
        }
    }

    @Test func persistsAcrossStoreInstances() throws {
        let all = try movies()
        withSuite { defaults in
            let first = makeVM(defaults)
            first.toggle(all[0])
            first.toggle(all[1])
            let second = makeVM(defaults)
            #expect(second.favorites == [all[0], all[1]])
        }
    }

    @Test func keepsInsertionOrder() throws {
        let all = try movies()
        let expected = [all[2].id, all[0].id, all[1].id]
        withSuite { defaults in
            let vm = makeVM(defaults)
            for movie in [all[2], all[0], all[1]] { vm.toggle(movie) }
            #expect(vm.favorites.map(\.id) == expected)
            #expect(makeVM(defaults).favorites.map(\.id) == expected)
        }
    }

    @Test func removeAtOffsetsPersists() throws {
        let all = try movies()
        let expected = [all[0].id, all[2].id]
        withSuite { defaults in
            let vm = makeVM(defaults)
            for movie in all.prefix(3) { vm.toggle(movie) }
            vm.remove(at: IndexSet(integer: 1))
            #expect(vm.favorites.map(\.id) == expected)
            #expect(makeVM(defaults).favorites.map(\.id) == expected)
        }
    }

    @Test func noDuplicates() throws {
        let movie = try movies()[0]
        withSuite { defaults in
            let store = UserDefaultsFavoritesStore(defaults: defaults)
            // Corrupt store holding the same movie twice.
            store.save([movie, movie])
            let vm = FavoritesViewModel(store: store)
            #expect(vm.favorites.count == 1)
            vm.toggle(movie)
            vm.toggle(movie)
            #expect(vm.favorites.count == 1)
        }
    }

    @Test func movieRoundTripsThroughStore() throws {
        let all = try movies()
        withSuite { defaults in
            let store = UserDefaultsFavoritesStore(defaults: defaults)
            store.save(all)
            #expect(store.load() == all)
        }
    }
}
