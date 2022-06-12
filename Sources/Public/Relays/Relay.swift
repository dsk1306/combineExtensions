import Combine

/// A publisher that exposes a method for outside callers to publish values.
/// It is identical to a `Subject`, but it cannot publish a finish event (until it's deallocated).
public protocol Relay: Publisher where Failure == Never {

  associatedtype Output

  /// Relays a value to the subscriber.
  /// - Parameter value: The value to send.
  func accept(_ value: Output)

  /// Attaches the specified publisher to this relay.
  /// - parameter publisher: An infallible publisher with the relay's `Output` type.
  /// - returns: `AnyCancellable`.
  func subscribe<P: Publisher>(_ publisher: P) -> AnyCancellable where P.Failure == Failure, P.Output == Output

}

public extension Relay where Output == Void {

  /// Relay a void to the subscriber.
  func accept() {
    accept(())
  }

}

// MARK: - Publisher Extensions

public extension Publisher where Failure == Never {

  /// Attaches the specified relay to this publisher.
  /// - parameter relay: Relay to attach to this publisher.
  /// - returns: `AnyCancellable`.
  func subscribe<R: Relay>(_ relay: R) -> AnyCancellable where R.Output == Output {
    relay.subscribe(self)
  }

}
