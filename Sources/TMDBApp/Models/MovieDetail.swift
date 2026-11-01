import Foundation

struct MovieDetail: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: Date?
    let voteAverage: Double
    let voteCount: Int
    let runtime: Int?
    let tagline: String?
    let genres: [Genre]
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, title, overview, posterPath, backdropPath, releaseDate, voteAverage, voteCount
        case runtime, tagline, genres, status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        overview = try c.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try c.decodeIfPresent(String.self, forKey: .backdropPath)
        releaseDate = try c.decodeTMDBDate(forKey: .releaseDate)
        voteAverage = try c.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        voteCount = try c.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        runtime = try c.decodeIfPresent(Int.self, forKey: .runtime)
        tagline = try c.decodeIfPresent(String.self, forKey: .tagline)
        genres = try c.decodeIfPresent([Genre].self, forKey: .genres) ?? []
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? ""
    }
}

extension MovieDetail {
    var year: String? { releaseDate.map(TMDBDate.year(of:)) }

    var ratingText: String { String(format: "%.1f", voteAverage) }
}
