import Combine

public extension Publisher {

  /// Replaces each upstream value with a constant.
  /// - Parameter value: The constant with which to replace each upstream value.
  /// - Returns: A new publisher wrapping the upstream, but with output type `Value`.
  func mapToValue<Value>(_ value: Value) -> Publishers.Map<Self, Value> {
    map { _ in value }
  }

  /// Replaces each upstream value with `Void`.
  /// - Returns: A new publisher wrapping the upstream and replacing each element with `Void`.
  func mapToVoid() -> Publishers.Map<Self, Void> {
    map { _ in () }
  }

}
