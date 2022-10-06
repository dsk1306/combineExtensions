import XCTest
import Combine
import CombineExtensions

final class CreateTests: XCTestCase {
    
    // MARK: - Properties
    
    private var cancelable: Cancellable?
    private var completion: Subscribers.Completion<CreateTests.MyError>?
    private var values = [String]()
    private var canceled = false
    private let allValues = ["Hello", "World", "What's", "Up?"]
    
    // MARK: - Base Class
    
    override func setUp() {
        canceled = false
        values = []
        completion = nil
        cancelable = nil
    }
    
    // MARK: - Tests
    
    func test_finished_unlimitedDemand() {
        let subscriber = makeSubscriber(demand: .unlimited)
        let publisher = makePublisher(fail: false)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, allValues)
    }
    
    func test_finished_limitedDemand() {
        let subscriber = makeSubscriber(demand: .max(2))
        
        let publisher = AnyPublisher<String, MyError> { subscriber in
            self.allValues.forEach { subscriber.send($0) }
            subscriber.send(completion: .finished)
            
            return AnyCancellable { [weak self] in
                self?.canceled = true
            }
        }
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }
    
    func test_finished_noDemand() {
        let subscriber = makeSubscriber(demand: .none)
        let publisher = makePublisher(fail: false)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .finished)
        XCTAssertTrue(canceled)
        XCTAssertTrue(values.isEmpty)
    }
    
    func test_error_unlimitedDemand() {
        let subscriber = makeSubscriber(demand: .unlimited)
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, allValues)
    }
    
    func test_error_limitedDemand() {
        let subscriber = makeSubscriber(demand: .max(2))
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }
    
    func test_error_noDemand() {
        let subscriber = makeSubscriber(demand: .none)
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .failure(MyError.failure))
        XCTAssertTrue(canceled)
        XCTAssertTrue(values.isEmpty)
    }
    
    func test_manualCancelation() {
        let publisher = AnyPublisher<String, Never>.create { _ in
            AnyCancellable { [weak self] in self?.canceled = true }
        }
        
        cancelable = publisher.sink { _ in }
        XCTAssertFalse(canceled)
        cancelable?.cancel()
        XCTAssertTrue(canceled)
    }
    
}

// MARK: - Private Helpers

private extension CreateTests {
    
    func makePublisher(fail: Bool = false) -> AnyPublisher<String, MyError> {
        AnyPublisher<String, MyError>.create { subscriber in
            self.allValues.forEach { subscriber.send($0) }
            subscriber.send(completion: fail ? .failure(MyError.failure) : .finished)
            
            return AnyCancellable { [weak self] in
                self?.canceled = true
            }
        }
        .eraseToAnyPublisher()
    }
    
    func makeSubscriber(demand: Subscribers.Demand) -> AnySubscriber<String, MyError> {
        AnySubscriber(
            receiveSubscription: { subscription in
                XCTAssertEqual("\(subscription)", "Create.Subscription<String, MyError>")
                subscription.request(demand)
            },
            receiveValue: { value in
                self.values.append(value)
                return .none
            },
            receiveCompletion: { finished in
                self.completion = finished
            }
        )
    }
    
}

// MARK: - MyError

private extension CreateTests {
    
    enum MyError: Swift.Error {
        
        case failure
        
    }
    
}
