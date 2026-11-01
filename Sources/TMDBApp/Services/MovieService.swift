protocol MovieService: Sendable {
    func popular(page: Int) async throws -> PagedResponse<Movie>
    func search(query: String, page: Int) async throws -> PagedResponse<Movie>
    func detail(id: Int) async throws -> MovieDetail
    func credits(id: Int) async throws -> Credits
}
