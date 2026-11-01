import Foundation

extension JSONDecoder {
    /// Shared decoder for TMDB responses (snake_case keys).
    static var tmdb: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

enum TMDBDate {
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    /// Parses `"yyyy-MM-dd"`; returns nil for empty or malformed strings.
    static func parse(_ string: String) -> Date? {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        return calendar.date(from: DateComponents(year: y, month: m, day: d))
    }

    /// Formats as `"yyyy-MM-dd"` (inverse of `parse`).
    static func string(from date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func year(of date: Date) -> String {
        String(calendar.component(.year, from: date))
    }
}

/// Shared display helpers for types carrying a release date and a vote average.
protocol ReleaseDated {
    var releaseDate: Date? { get }
    var voteAverage: Double { get }
}

extension ReleaseDated {
    var year: String? { releaseDate.map(TMDBDate.year(of:)) }

    var ratingText: String { String(format: "%.1f", voteAverage) }
}

extension KeyedDecodingContainer {
    /// Decodes an optional TMDB date, treating missing, null, or empty string as nil.
    func decodeTMDBDate(forKey key: Key) throws -> Date? {
        guard let string = try decodeIfPresent(String.self, forKey: key) else { return nil }
        return TMDBDate.parse(string)
    }
}
