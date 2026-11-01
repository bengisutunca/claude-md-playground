import Foundation
import Testing
@testable import TMDBApp

@MainActor
@Suite("Favorites")
struct FavoritesTests {
    /// A unique, isolated `UserDefaults` suite that is wiped on `cleanUp()`.
    private struct TestSuite {
        let name = "FavoritesTests-\(UUID().uuidString)"
        let defaults: UserDefaults

        init() {
            defaults = UserDefaults(suiteName: name)!
        }

        func makeStore() -> UserDefaultsFavoritesStore { UserDefaultsFavoritesStore(defaults: defaults) }

        func cleanUp() { defaults.removePersistentDomain(forName: name) }
    }

    private func movies() throws -> [Movie] {
        let page = try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: Fixture.data("popular_page1"))
        try #require(page.results.count >= 3)
        return page.results
    }

    @Test func toggleOnAndOff() throws {
        let suite = TestSuite(); defer { suite.cleanUp() }
        let movie = try movies()[0]
        let vm = FavoritesViewModel(store: suite.makeStore())
        #expect(!vm.isFavorite(movie))
        vm.toggle(movie)
        #expect(vm.isFavorite(movie))
        #expect(vm.favorites == [movie])
        vm.toggle(movie)
        #expect(!vm.isFavorite(movie))
        #expect(vm.favorites.isEmpty)
    }

    @Test func persistsAcrossStoreInstances() throws {
        let suite = TestSuite(); defer { suite.cleanUp() }
        let all = try movies()
        let first = FavoritesViewModel(store: suite.makeStore())
        first.toggle(all[0])
        first.toggle(all[1])

        let second = FavoritesViewModel(store: suite.makeStore())
        // Full `Movie` values (not just ids) survive the round trip.
        #expect(second.favorites == [all[0], all[1]])
        #expect(second.favorites.map(\.title) == [all[0].title, all[1].title])
        #expect(second.favorites[0].releaseDate == all[0].releaseDate)
    }

    @Test func insertionOrderKept() throws {
        let suite = TestSuite(); defer { suite.cleanUp() }
        let all = try movies()
        let vm = FavoritesViewModel(store: suite.makeStore())
        let order = [all[2], all[0], all[1]]
        order.forEach(vm.toggle)
        #expect(vm.favorites == order)
        #expect(FavoritesViewModel(store: suite.makeStore()).favorites == order)
    }

    @Test func removalByOffsetPersists() throws {
        let suite = TestSuite(); defer { suite.cleanUp() }
        let all = try movies()
        let vm = FavoritesViewModel(store: suite.makeStore())
        all.prefix(3).forEach(vm.toggle)
        vm.remove(at: IndexSet(integer: 1))
        #expect(vm.favorites == [all[0], all[2]])
        #expect(!vm.isFavorite(all[1]))
        #expect(FavoritesViewModel(store: suite.makeStore()).favorites == [all[0], all[2]])
    }

    @Test func noDuplicates() throws {
        let suite = TestSuite(); defer { suite.cleanUp() }
        let movie = try movies()[0]
        let store = suite.makeStore()
        // Store-level: duplicates handed to save() are collapsed.
        store.save([movie, movie])
        #expect(store.load() == [movie])
        // View-model level: the store already holds `movie`, so toggling removes it, then re-adds once.
        let vm = FavoritesViewModel(store: suite.makeStore())
        #expect(vm.favorites == [movie])
        vm.toggle(movie)
        vm.toggle(movie)
        #expect(vm.favorites == [movie])
        #expect(vm.favorites.filter { $0.id == movie.id }.count == 1)
    }
}
