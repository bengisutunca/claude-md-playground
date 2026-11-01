import Foundation

struct ImageURLBuilder: Sendable {
    enum Size: String, Sendable, CaseIterable {
        case w185, w342, w780, original
    }

    let baseURL: URL

    init(baseURL: URL = TMDBApp.imageBaseURL) {
        self.baseURL = baseURL
    }

    /// Returns `<base>/<size><path>`, or nil when `path` is nil or empty.
    func url(path: String?, size: Size) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        let normalized = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent(size.rawValue).appendingPathComponent(normalized)
    }
}
