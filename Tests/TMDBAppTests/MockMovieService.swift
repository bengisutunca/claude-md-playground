import Foundation
@testable import TMDBApp

/// Reusable `MovieService` double: returns fixture data, or throws `error` if set. Records calls.
actor MockMovieService: MovieService {
    enum Call: Equatable, Sendable {
        case popular(page: Int)
        case search(query: String, page: Int)
        case detail(id: Int)
        case credits(id: Int)
    }

    var error: Error?
    private(set) var calls: [Call] = []

    init(error: Error? = nil) { self.error = error }

    func setError(_ error: Error?) { self.error = error }

    private func decode<T: Decodable>(_ fixture: String, as type: T.Type) throws -> T {
        if let error { throw error }
        return try JSONDecoder.tmdb.decode(T.self, from: Fixture.data(fixture))
    }

    func popular(page: Int) async throws -> PagedResponse<Movie> {
        calls.append(.popular(page: page))
        return try decode(page == 2 ? "popular_page2" : "popular_page1", as: PagedResponse<Movie>.self)
    }

    func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
        calls.append(.search(query: query, page: page))
        return try decode(query.isEmpty || query == "empty" ? "search_empty" : "search_inception",
                          as: PagedResponse<Movie>.self)
    }

    func detail(id: Int) async throws -> MovieDetail {
        calls.append(.detail(id: id))
        return try decode("movie_detail_27205", as: MovieDetail.self)
    }

    func credits(id: Int) async throws -> Credits {
        calls.append(.credits(id: id))
        return try decode("movie_credits_27205", as: Credits.self)
    }
}
