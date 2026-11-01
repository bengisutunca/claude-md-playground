import Foundation

enum APIError: Error {
    case invalidResponse
    case httpStatus(code: Int, message: String?)
    case decoding(Error)
    case transport(Error)
    case missingAPIKey
}

/// TMDB error body, e.g. `{"status_code": 7, "status_message": "...", "success": false}`.
struct TMDBErrorBody: Decodable {
    let statusMessage: String
}
