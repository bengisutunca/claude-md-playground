import Foundation

extension JSONDecoder {
    /// Shared decoder for TMDB payloads: snake_case keys become camelCase.
    static var tmdb: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

enum TMDBDate {
    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Parses `"yyyy-MM-dd"`. Empty or malformed string gives `nil`.
    static func parse(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = utcCalendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    static func year(of date: Date?) -> String? {
        guard let date else { return nil }
        return String(utcCalendar.component(.year, from: date))
    }
}
