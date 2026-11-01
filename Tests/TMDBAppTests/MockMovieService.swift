import Foundation
@testable import TMDBApp

/// Reusable `MovieService` double. Returns fixture data, or throws `error` when set. Records calls.
final class MockMovieService: MovieService, @unchecked Sendable {
    enum Call: Equatable {
        case popular(page: Int)
        case search(query: String, page: Int)
        case detail(id: Int)
        case credits(id: Int)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _error: Error?

    var calls: [Call] { lock.withLock { _calls } }

    var error: Error? {
        get { lock.withLock { _error } }
        set { lock.withLock { _error = newValue } }
    }

    init(error: Error? = nil) {
        _error = error
    }

    private func record(_ call: Call) throws {
        let error = lock.withLock { () -> Error? in
            _calls.append(call)
            return _error
        }
        if let error { throw error }
    }

    private func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        try JSONDecoder.tmdb.decode(T.self, from: Fixture.data(name))
    }

    func popular(page: Int) async throws -> PagedResponse<Movie> {
        try record(.popular(page: page))
        return try load(page == 2 ? "popular_page2" : "popular_page1", as: PagedResponse<Movie>.self)
    }

    func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
        try record(.search(query: query, page: page))
        let name = query.lowercased().contains("inception") ? "search_inception" : "search_empty"
        return try load(name, as: PagedResponse<Movie>.self)
    }

    func detail(id: Int) async throws -> MovieDetail {
        try record(.detail(id: id))
        return try load("movie_detail_27205", as: MovieDetail.self)
    }

    func credits(id: Int) async throws -> Credits {
        try record(.credits(id: id))
        return try load("movie_credits_27205", as: Credits.self)
    }
}
