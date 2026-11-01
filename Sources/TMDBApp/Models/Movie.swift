import Foundation

struct Movie: Identifiable, Hashable, Sendable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: Date?
    let voteAverage: Double
    let voteCount: Int
    let genreIDs: [Int]

    init(
        id: Int, title: String, overview: String = "", posterPath: String? = nil,
        backdropPath: String? = nil, releaseDate: Date? = nil, voteAverage: Double = 0,
        voteCount: Int = 0, genreIDs: [Int] = []
    ) {
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

    private enum CodingKeys: String, CodingKey {
        case id, title, overview, posterPath, backdropPath, releaseDate
        case voteAverage, voteCount
        case genreIDs = "genreIds"  // convertFromSnakeCase turns genre_ids into genreIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        overview = try c.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try c.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try c.decodeIfPresent(String.self, forKey: .backdropPath)
        releaseDate = TMDBDate.parse(try c.decodeIfPresent(String.self, forKey: .releaseDate))
        voteAverage = try c.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        voteCount = try c.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        genreIDs = try c.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
    }

    /// Summary built from a full detail payload.
    init(detail: MovieDetail) {
        self.init(
            id: detail.id, title: detail.title, overview: detail.overview,
            posterPath: detail.posterPath, backdropPath: detail.backdropPath,
            releaseDate: detail.releaseDate, voteAverage: detail.voteAverage,
            voteCount: detail.voteCount, genreIDs: detail.genres.map(\.id))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(overview, forKey: .overview)
        try c.encodeIfPresent(posterPath, forKey: .posterPath)
        try c.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try c.encodeIfPresent(TMDBDate.string(from: releaseDate), forKey: .releaseDate)
        try c.encode(voteAverage, forKey: .voteAverage)
        try c.encode(voteCount, forKey: .voteCount)
        try c.encode(genreIDs, forKey: .genreIDs)
    }

    /// Release year, e.g. "2010". `nil` when release date is unknown.
    var year: String? { TMDBDate.year(of: releaseDate) }

    /// Rating with one decimal, e.g. "8.4".
    var ratingText: String { String(format: "%.1f", voteAverage) }
}
