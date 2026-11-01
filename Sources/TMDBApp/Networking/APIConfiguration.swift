import Foundation

/// Holds the TMDB API key and base URL. The key is never hard-coded: it comes from the
/// `TMDB_API_KEY` environment variable or the `TMDB_API_KEY` Info.plist key.
struct APIConfiguration: Sendable {
    static let keyName = "TMDB_API_KEY"

    let apiKey: String
    let baseURL: URL

    init(apiKey: String, baseURL: URL = TMDBApp.apiBaseURL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    /// Resolves the key from the environment, then from the bundle's Info.plist.
    /// Throws `APIError.missingAPIKey` if neither provides a non-empty value.
    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main
    ) throws -> APIConfiguration {
        if let key = environment[keyName]?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            return APIConfiguration(apiKey: key)
        }
        if let key = (bundle.object(forInfoDictionaryKey: keyName) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            return APIConfiguration(apiKey: key)
        }
        throw APIError.missingAPIKey
    }
}
