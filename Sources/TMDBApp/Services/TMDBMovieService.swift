struct TMDBMovieService: MovieService {
    private let client: any HTTPClient

    init(client: any HTTPClient) {
        self.client = client
    }

    func popular(page: Int) async throws -> PagedResponse<Movie> {
        try await client.send(.popular(page: page), as: PagedResponse<Movie>.self)
    }

    func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
        try await client.send(.search(query: query, page: page), as: PagedResponse<Movie>.self)
    }

    func detail(id: Int) async throws -> MovieDetail {
        try await client.send(.movieDetail(id: id), as: MovieDetail.self)
    }

    func credits(id: Int) async throws -> Credits {
        try await client.send(.credits(movieID: id), as: Credits.self)
    }
}
