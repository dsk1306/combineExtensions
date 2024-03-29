import Combine
import Foundation

public extension AnyPublisher {
    
    /// Creates a publisher which accepts a closure with a subscriber argument, to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in which you can define any cleanup actions to execute when the pubilsher completes or the subscription to the publisher is canceled.
    /// - Parameter factory: A factory with a closure to which you can dynamically send value or completion events. You should return a `Cancelable`-conforming object from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    /// ```
    /// AnyPublisher<String, MyError>.create { subscriber in
    ///   // Values
    ///   subscriber.send("Hello")
    ///   subscriber.send("World!")
    ///
    ///   // Complete with error
    ///   subscriber.send(completion: .failure(MyError.someError))
    ///
    ///   // Or, complete successfully
    ///   subscriber.send(completion: .finished)
    ///
    ///   return AnyCancellable {
    ///     // Perform clean-up
    ///   }
    /// }
    /// ```
    init(_ factory: @escaping Publishers.Create<Output, Failure>.SubscriberHandler) {
        self = Publishers.Create(factory: factory).eraseToAnyPublisher()
    }
    
    /// Creates a publisher which accepts a closure with a subscriber argument, to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in which you can define any cleanup actions to execute when the pubilsher completes or the subscription to the publisher is canceled.
    /// - Parameter factory: A factory with a closure to which you can dynamically send value or completion events. You should return a `Cancelable`-conforming object from it to encapsulate any cleanup-logic for your work.
    ///
    /// An example usage could look as follows:
    ///
    /// ```
    /// AnyPublisher<String, MyError>.create { subscriber in
    ///   // Values
    ///   subscriber.send("Hello")
    ///   subscriber.send("World!")
    ///
    ///   // Complete with error
    ///   subscriber.send(completion: .failure(MyError.someError))
    ///
    ///   // Or, complete successfully
    ///   subscriber.send(completion: .finished)
    ///
    ///   return AnyCancellable {
    ///     // Perform clean-up
    ///   }
    /// }
    /// ```
    static func create(_ factory: @escaping Publishers.Create<Output, Failure>.SubscriberHandler)
    -> AnyPublisher<Output, Failure> {
        AnyPublisher(factory)
    }
    
}

// MARK: - Create

public extension Publishers {
    
    /// A publisher which accepts a closure with a subscriber argument, to which you can dynamically send value or completion events.
    ///
    /// You should return a `Cancelable`-conforming object from the closure in which you can define any cleanup actions to execute when the pubilsher completes or the subscription to the publisher is canceled.
    struct Create<Output, Failure: Swift.Error>: Publisher {
        
        public typealias SubscriberHandler = (Subscriber) -> Cancellable
        private let factory: SubscriberHandler
        
        /// Initialize the publisher with a provided factory.
        /// - Parameter factory: A factory with a closure to which you can dynamically push value or completion events.
        public init(factory: @escaping SubscriberHandler) {
            self.factory = factory
        }
        
        public func receive<S: Combine.Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(factory: factory, downstream: subscriber))
        }
        
    }
    
}

// MARK: - Subscription

private extension Publishers.Create {
    
    final class Subscription<Downstream: Combine.Subscriber>: Combine.Subscription where Output == Downstream.Input, Failure == Downstream.Failure {
        
        private let buffer: DemandBuffer<Downstream>
        private var cancelable: Cancellable?
        
        init(factory: @escaping SubscriberHandler,
             downstream: Downstream) {
            buffer = DemandBuffer(subscriber: downstream)
            
            let subscriber = Subscriber(
                onValue: { [weak self] in _ = self?.buffer.buffer(value: $0) },
                onCompletion: { [weak self] in self?.buffer.complete(completion: $0) }
            )
            
            cancelable = factory(subscriber)
        }
        
        func request(_ demand: Subscribers.Demand) {
            _ = buffer.demand(demand)
        }
        
        func cancel() {
            cancelable?.cancel()
        }
        
    }
    
}

extension Publishers.Create.Subscription: CustomStringConvertible {
    
    var description: String {
        "Create.Subscription<\(Output.self), \(Failure.self)>"
    }
    
}

// MARK: - Subscriber

public extension Publishers.Create {
    
    struct Subscriber {
        
        private let onValue: (Output) -> Void
        private let onCompletion: (Subscribers.Completion<Failure>) -> Void
        
        fileprivate init(onValue: @escaping (Output) -> Void,
                         onCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
            self.onValue = onValue
            self.onCompletion = onCompletion
        }
        
        /// Sends a value to the subscriber.
        /// - Parameter input: The value to send.
        public func send(_ input: Output) {
            onValue(input)
        }
        
        /// Sends a completion event to the subscriber.
        /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
        public func send(completion: Subscribers.Completion<Failure>) {
            onCompletion(completion)
        }
        
    }
    
}
