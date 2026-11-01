import Foundation

/// Offline `MovieService` with canned data, for SwiftUI previews.
struct PreviewMovieService: MovieService {
    static let movies: [Movie] = [
        Movie(id: 27205, title: "Inception", overview: "A thief enters dreams.",
              releaseDate: TMDBDate.parse("2010-07-15"), voteAverage: 8.4, voteCount: 35000),
        Movie(id: 155, title: "The Dark Knight", overview: "Batman faces the Joker.",
              releaseDate: TMDBDate.parse("2008-07-16"), voteAverage: 8.5, voteCount: 31000),
        Movie(id: 603, title: "The Matrix", overview: "A hacker learns the truth.",
              releaseDate: TMDBDate.parse("1999-03-30"), voteAverage: 8.2, voteCount: 25000)
    ]

    private static let detailJSON = """
        {"id": 27205, "title": "Inception", "overview": "A thief enters dreams.",
         "release_date": "2010-07-15", "vote_average": 8.4, "vote_count": 35000,
         "runtime": 148, "tagline": "Your mind is the scene of the crime.",
         "genres": [{"id": 28, "name": "Action"}, {"id": 878, "name": "Science Fiction"}],
         "status": "Released"}
        """

    private static let creditsJSON = """
        {"id": 27205,
         "cast": [{"id": 6193, "name": "Leonardo DiCaprio", "character": "Cobb", "order": 0},
                  {"id": 24045, "name": "Joseph Gordon-Levitt", "character": "Arthur", "order": 1}],
         "crew": [{"id": 525, "name": "Christopher Nolan", "job": "Director", "department": "Directing"}]}
        """

    func popular(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: Self.movies, totalPages: 1, totalResults: Self.movies.count)
    }

    func search(query: String, page: Int) async throws -> PagedResponse<Movie> {
        let hits = Self.movies.filter { $0.title.localizedCaseInsensitiveContains(query) }
        return PagedResponse(page: 1, results: hits, totalPages: 1, totalResults: hits.count)
    }

    func detail(id: Int) async throws -> MovieDetail {
        try JSONDecoder.tmdb.decode(MovieDetail.self, from: Data(Self.detailJSON.utf8))
    }

    func credits(id: Int) async throws -> Credits {
        try JSONDecoder.tmdb.decode(Credits.self, from: Data(Self.creditsJSON.utf8))
    }
}
