import Foundation
import Testing
@testable import TMDBApp

// Hidden acceptance test: copied in by the benchmark harness after the session ends.
// The agent never sees this file. Self-contained: it does not use any test helper the agent wrote.

private struct AccMissingFixture: Error { let name: String }

private func accData(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
        throw AccMissingFixture(name: name)
    }
    return try Data(contentsOf: url)
}

@MainActor
@Suite("Acceptance 07: favorites", .serialized)
struct Acceptance07Tests {
    private func movies() throws -> [Movie] {
        try JSONDecoder.tmdb.decode(PagedResponse<Movie>.self, from: accData("popular_page1")).results
    }

    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let name = "acceptance.favorites.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    @Test func toggleOnAndOff() throws {
        let m = try movies()
        try withDefaults { defaults in
            let vm = FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
            #expect(vm.favorites.isEmpty)
            vm.toggle(m[0])
            #expect(vm.isFavorite(m[0]))
            #expect(vm.favorites.map(\.id) == [m[0].id])
            vm.toggle(m[0])
            #expect(vm.isFavorite(m[0]) == false)
            #expect(vm.favorites.isEmpty)
        }
    }

    @Test func persistsAcrossInstances() throws {
        let m = try movies()
        try withDefaults { defaults in
            let first = FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
            first.toggle(m[0])
            first.toggle(m[4])
            let second = FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
            #expect(second.favorites.map(\.id) == [m[0].id, m[4].id])
            let inception = try #require(second.favorites.first)
            #expect(inception.title == "Inception")
            #expect(inception.posterPath == "/inception.jpg")
            #expect(inception.releaseDate == m[0].releaseDate)
            #expect(inception.year == "2010")
            #expect(second.favorites.last?.posterPath == nil)
        }
    }

    @Test func keepsInsertionOrder() throws {
        let m = try movies()
        try withDefaults { defaults in
            let vm = FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
            vm.toggle(m[2]); vm.toggle(m[0]); vm.toggle(m[1])
            #expect(vm.favorites.map(\.id) == [m[2].id, m[0].id, m[1].id])
            let reloaded = UserDefaultsFavoritesStore(defaults: defaults).load()
            #expect(reloaded.map(\.id) == [m[2].id, m[0].id, m[1].id])
        }
    }

    @Test func removeAtOffsetsPersists() throws {
        let m = try movies()
        try withDefaults { defaults in
            let vm = FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
            vm.toggle(m[0]); vm.toggle(m[1]); vm.toggle(m[2])
            vm.remove(at: IndexSet(integer: 1))
            #expect(vm.favorites.map(\.id) == [m[0].id, m[2].id])
            let reloaded = FavoritesViewModel(store: UserDefaultsFavoritesStore(defaults: defaults))
            #expect(reloaded.favorites.map(\.id) == [m[0].id, m[2].id])
        }
    }

    @Test func storeRoundTrip() throws {
        let m = try movies()
        try withDefaults { defaults in
            let store = UserDefaultsFavoritesStore(defaults: defaults)
            store.save([m[3], m[1]])
            #expect(UserDefaultsFavoritesStore(defaults: defaults).load().map(\.id) == [m[3].id, m[1].id])
        }
    }

    @Test func separateKeysAreIndependent() throws {
        let m = try movies()
        try withDefaults { defaults in
            UserDefaultsFavoritesStore(defaults: defaults, key: "a").save([m[0]])
            #expect(UserDefaultsFavoritesStore(defaults: defaults, key: "b").load().isEmpty)
            #expect(UserDefaultsFavoritesStore(defaults: defaults, key: "a").load().map(\.id) == [m[0].id])
        }
    }
}
