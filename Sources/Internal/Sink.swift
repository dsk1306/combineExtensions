import Combine

/// A generic sink using an underlying demand buffer to balance the demand of a downstream subscriber for the events of an upstream publisher.
class Sink<Upstream: Publisher, Downstream: Subscriber>: Subscriber {

  // MARK: - Typealiases

  typealias TransformFailure = (Upstream.Failure) -> Downstream.Failure?
  typealias TransformOutput = (Upstream.Output) -> Downstream.Input?

  // MARK: - Properties

  private(set) var buffer: DemandBuffer<Downstream>

  private var upstreamSubscription: Subscription?
  private let transformOutput: TransformOutput?
  private let transformFailure: TransformFailure?
  private var upstreamIsCancelled = false

  // MARK: - Initialization

  /// Initialize a new sink subscribing to the upstream publisher and fulfilling the demand of the downstream subscriber using a backpresurre demand-maintaining buffer.
  ///
  /// - Note: You **must** provide the two transformation functions above if you're using the default `Sink` implementation. Otherwise, you must subclass `Sink` with your own publisher's sink and manage the buffer accordingly.
  /// - Parameters:
  ///   - upstream: The upstream publisher.
  ///   - downstream: The downstream subscriber.
  ///   - transformOutput: Transform the upstream publisher's output type to the downstream's input type.
  ///   - transformFailure: Transform the upstream failure type to the downstream's failure type.
  init(upstream: Upstream,
       downstream: Downstream,
       transformOutput: TransformOutput? = nil,
       transformFailure: TransformFailure? = nil) {
    self.buffer = DemandBuffer(subscriber: downstream)
    self.transformOutput = transformOutput
    self.transformFailure = transformFailure

    // A subscription can only be cancelled once.
    // The `upstreamIsCancelled` value is used to suppress a second call to cancel when the `Sink` is deallocated, when a sink receives completion, and when a custom operator like `withLatestFrom` calls `cancelUpstream()` manually.
    upstream
      .handleEvents(
        receiveCancel: { [weak self] in
          self?.upstreamIsCancelled = true
        }
      )
      .subscribe(self)
  }

  deinit { cancelUpstream() }

  // MARK: - Subscriber

  func receive(subscription: Subscription) {
    upstreamSubscription = subscription
  }

  func receive(_ input: Upstream.Output) -> Subscribers.Demand {
    guard let transform = transformOutput else {
      fatalError("""
                ❌ Missing output transformation
                =========================

                You must either:
                    - Provide a transformation function from the upstream's output to the downstream's input; or
                    - Subclass `Sink` with your own publisher's Sink and manage the buffer yourself
            """)
    }

    guard let input = transform(input) else { return .none }
    return buffer.buffer(value: input)
  }

  func receive(completion: Subscribers.Completion<Upstream.Failure>) {
    switch completion {
    case .finished:
      buffer.complete(completion: .finished)
    case .failure(let error):
      guard let transform = transformFailure else {
        fatalError("""
                    ❌ Missing failure transformation
                    =========================

                    You must either:
                        - Provide a transformation function from the upstream's failure to the downstream's failuer; or
                        - Subclass `Sink` with your own publisher's Sink and manage the buffer yourself
                """)
      }

      guard let error = transform(error) else { return }
      buffer.complete(completion: .failure(error))
    }

    cancelUpstream()
  }

}

// MARK: - Public Methods

extension Sink {

  func demand(_ demand: Subscribers.Demand) {
    let newDemand = buffer.demand(demand)
    upstreamSubscription?.requestIfNeeded(newDemand)
  }

  func cancelUpstream() {
    guard upstreamIsCancelled == false else { return }
    upstreamSubscription.kill()
  }

}
