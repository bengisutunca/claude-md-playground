import Foundation

struct APIConfiguration: Sendable {
    static let keyName = "TMDB_API_KEY"

    let apiKey: String
    let baseURL: URL

    init(apiKey: String, baseURL: URL = URL(string: "https://api.themoviedb.org/3")!) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    /// Reads `TMDB_API_KEY` from the environment, then from the bundle Info.plist.
    /// Throws `APIError.missingAPIKey` when neither holds a non-empty value.
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
