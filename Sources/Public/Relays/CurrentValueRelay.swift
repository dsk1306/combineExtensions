import Combine

/// A relay that wraps a single value and publishes a new element whenever the value changes.
///
/// Unlike its subject-counterpart, it may only accept values, and only sends a finishing event on deallocation.
/// It cannot send a failure event.
/// - Note: Unlike `PassthroughRelay`, `CurrentValueRelay` maintains a buffer of the most recently published value.
public final class CurrentValueRelay<Output>: Relay {

  // MARK: - Properties

  public var value: Output { storage.value }

  private let storage: CurrentValueSubject<Output, Never>
  private var subscriptions = [Subscription<CurrentValueSubject<Output, Never>, AnySubscriber<Output, Never>>]()

  // MARK: - Initialization

  /// Create a new relay.
  /// - Parameter value: Initial value for the relay.
  public init(_ value: Output) {
    storage = .init(value)
  }

  deinit {
    // Send a finished event upon dealloation.
    subscriptions.forEach { $0.forceFinish() }
  }

  // MARK: - Public Methods

  /// Relay a value to downstream subscribers.
  /// - Parameter value: A new value.
  public func accept(_ value: Output) {
    storage.send(value)
  }

  public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Failure == S.Failure {
    let subscription = Subscription(upstream: storage, downstream: AnySubscriber(subscriber))
    self.subscriptions.append(subscription)
    subscriber.receive(subscription: subscription)
  }

  public func subscribe<P: Publisher>(_ publisher: P) -> AnyCancellable where Output == P.Output, P.Failure == Never {
    publisher.subscribe(storage)
  }

  public func subscribe<P: Relay>(_ publisher: P) -> AnyCancellable where Output == P.Output {
    publisher.subscribe(storage)
  }

}

// MARK: - Subscription

private extension CurrentValueRelay {

  final class Subscription<Upstream: Publisher, Downstream: Subscriber>: Combine.Subscription where Upstream.Output == Downstream.Input, Upstream.Failure == Downstream.Failure {

    private var sink: Sink<Upstream, Downstream>?

    var shouldForwardCompletion: Bool {
      get { sink?.shouldForwardCompletion ?? false }
      set { sink?.shouldForwardCompletion = newValue }
    }

    init(upstream: Upstream,
         downstream: Downstream) {
      self.sink = Sink(
        upstream: upstream,
        downstream: downstream,
        transformOutput: { $0 }
      )
    }

    func forceFinish() {
      sink?.shouldForwardCompletion = true
      sink?.receive(completion: .finished)
      sink = nil
    }

    func request(_ demand: Subscribers.Demand) {
      sink?.demand(demand)
    }

    func cancel() {
      forceFinish()
    }

  }

}

// MARK: - Sink

private extension CurrentValueRelay {

  final class Sink<Upstream: Publisher, Downstream: Subscriber>: CombineExtensions.Sink<Upstream, Downstream> {

    var shouldForwardCompletion = false

    override func receive(completion: Subscribers.Completion<Upstream.Failure>) {
      guard shouldForwardCompletion else { return }
      super.receive(completion: completion)
    }

  }

}
