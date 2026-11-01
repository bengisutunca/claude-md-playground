import Foundation

protocol HTTPClient: Sendable {
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T
}
