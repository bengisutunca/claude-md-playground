import Foundation

enum APIError: Error {
    case invalidResponse
    case httpStatus(code: Int, message: String?)
    case decoding(Error)
    case transport(Error)
    case missingAPIKey
}

extension Error {
    /// User-facing description, suitable for an error screen.
    var userMessage: String {
        guard let apiError = self as? APIError else {
            return "Something went wrong. Please try again."
        }
        switch apiError {
        case .missingAPIKey:
            return "The TMDB API key is missing. Set TMDB_API_KEY in the environment or Info.plist."
        case .httpStatus(let code, let message):
            if code == 401 { return "Invalid API key." }
            return message ?? "The server returned an error (\(code))."
        case .transport:
            return "Couldn't reach the server. Check your connection."
        case .decoding, .invalidResponse:
            return "Received an unexpected response from the server."
        }
    }
}

/// TMDB error body, e.g. `{"status_code": 7, "status_message": "...", "success": false}`.
struct TMDBErrorBody: Decodable {
    let statusMessage: String
}
