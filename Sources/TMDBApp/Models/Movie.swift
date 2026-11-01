import Foundation

struct Movie: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: Date?
    let voteAverage: Double
    let voteCount: Int
    let genreIDs: [Int]

    enum CodingKeys: String, CodingKey {
        case id, title, overview, posterPath, backdropPath, releaseDate, voteAverage, voteCount
        // Key after `.convertFromSnakeCase` is applied to "genre_ids".
        case genreIDs = "genreIds"
    }

    init(id: Int, title: String, overview: String = "", posterPath: String? = nil,
         backdropPath: String? = nil, releaseDate: Date? = nil, voteAverage: Double = 0,
         voteCount: Int = 0, genreIDs: [Int] = []) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.genreIDs = genreIDs
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
        genreIDs = try c.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
    }
}

extension Movie {
    var year: String? { releaseDate.map(TMDBDate.year(of:)) }

    var ratingText: String { String(format: "%.1f", voteAverage) }
}
