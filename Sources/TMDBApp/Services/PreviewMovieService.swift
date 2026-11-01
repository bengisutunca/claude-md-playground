import Foundation

/// In-memory `MovieService` with static sample data, for SwiftUI previews. Never touches the network.
struct PreviewMovieService: MovieService {
    static let movies: [Movie] = [
        Movie(id: 1, title: "Inception", overview: "A thief who steals secrets through dreams.",
              releaseDate: TMDBDate.parse("2010-07-15"), voteAverage: 8.4, voteCount: 35000),
        Movie(id: 2, title: "Interstellar", overview: "Explorers travel through a wormhole.",
              releaseDate: TMDBDate.parse("2014-11-05"), voteAverage: 8.5, voteCount: 33000),
        Movie(id: 3, title: "The Dark Knight", overview: "Batman faces the Joker.",
              releaseDate: TMDBDate.parse("2008-07-16"), voteAverage: 8.5, voteCount: 31000)
    ]

    private static let detailJSON = """
    {"id": 1, "title": "Inception", "overview": "A thief who steals secrets through dreams.",
     "release_date": "2010-07-15", "vote_average": 8.4, "vote_count": 35000, "runtime": 148,
     "tagline": "Your mind is the scene of the crime.", "status": "Released",
     "genres": [{"id": 28, "name": "Action"}, {"id": 878, "name": "Science Fiction"}]}
    """

    private static let creditsJSON = """
    {"id": 1,
     "cast": [{"id": 6193, "name": "Leonardo DiCaprio", "character": "Cobb", "order": 0}],
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
