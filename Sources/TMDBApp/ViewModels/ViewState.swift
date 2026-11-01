import Foundation

/// Load state shared by view models.
enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(String)
}

extension ViewState: Equatable where Value: Equatable {}
extension ViewState: Sendable where Value: Sendable {}
