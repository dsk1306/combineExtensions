import Combine
@testable import CombineExtensions
import XCTest

final class CreateTests: XCTestCase {
    
    // MARK: - Properties
    
    private var cancelable: Cancellable?
    private var completion: Subscribers.Completion<TestError>?
    private var values = [String]()
    private var canceled = false
    private let allValues = ["Hello", "World", "What's", "Up?"]
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()

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
        
        let publisher = AnyPublisher<String, TestError> { [weak self] subscriber in
            self?.allValues.forEach { subscriber.send($0) }
            subscriber.send(completion: .finished)
            
            return AnyCancellable {
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
        
        XCTAssertEqual(completion, .failure(TestError.test))
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, allValues)
    }
    
    func test_error_limitedDemand() {
        let subscriber = makeSubscriber(demand: .max(2))
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .failure(TestError.test))
        XCTAssertTrue(canceled)
        XCTAssertEqual(values, Array(allValues.prefix(2)))
    }
    
    func test_error_noDemand() {
        let subscriber = makeSubscriber(demand: .none)
        let publisher = makePublisher(fail: true)
        
        publisher.subscribe(subscriber)
        
        XCTAssertEqual(completion, .failure(TestError.test))
        XCTAssertTrue(canceled)
        XCTAssertTrue(values.isEmpty)
    }
    
    func test_manualCancelation() {
        let publisher = AnyPublisher<String, Never>.create { [weak self] _ in
            AnyCancellable { self?.canceled = true }
        }
        
        cancelable = publisher.sink { _ in }
        XCTAssertFalse(canceled)
        cancelable?.cancel()
        XCTAssertTrue(canceled)
    }
    
}

// MARK: - Helpers

private extension CreateTests {
    
    func makePublisher(fail: Bool = false) -> AnyPublisher<String, TestError> {
        AnyPublisher<String, TestError>.create { [weak self] subscriber in
            self?.allValues.forEach { subscriber.send($0) }
            subscriber.send(completion: fail ? .failure(.test) : .finished)
            
            return AnyCancellable {
                self?.canceled = true
            }
        }
        .eraseToAnyPublisher()
    }
    
    func makeSubscriber(demand: Subscribers.Demand) -> AnySubscriber<String, TestError> {
        AnySubscriber(
            receiveSubscription: { subscription in
                XCTAssertEqual("\(subscription)", "Create.Subscription<String, TestError>")
                subscription.request(demand)
            },
            receiveValue: { [weak self] value in
                self?.values.append(value)
                return .none
            },
            receiveCompletion: { [weak self] finished in
                self?.completion = finished
            }
        )
    }
    
}
