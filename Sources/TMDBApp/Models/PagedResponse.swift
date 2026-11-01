struct PagedResponse<T: Decodable>: Decodable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int
}

extension PagedResponse: Sendable where T: Sendable {}
extension PagedResponse: Equatable where T: Equatable {}
extension PagedResponse: Hashable where T: Hashable {}
