import Foundation

enum APIError: Error {
    case invalidResponse
    case httpStatus(code: Int, message: String?)
    case decoding(Error)
    case transport(Error)
    case missingAPIKey
}

/// TMDB error body. Only `status_message` is read.
struct TMDBErrorBody: Decodable {
    let statusMessage: String
}
