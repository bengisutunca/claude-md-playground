struct PagedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int
}

extension PagedResponse: Equatable where T: Equatable {}
extension PagedResponse: Hashable where T: Hashable {}
