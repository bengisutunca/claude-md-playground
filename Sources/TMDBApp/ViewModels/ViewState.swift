enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(String)
}

extension ViewState: Sendable where Value: Sendable {}
extension ViewState: Equatable where Value: Equatable {}
