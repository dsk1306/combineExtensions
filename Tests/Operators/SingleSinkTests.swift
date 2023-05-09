import Combine
@testable import CombineExtensions
import XCTest

final class SingleSinkTests: XCTestCase {
    
    // MARK: - Properties
    
    private var source: PassthroughSubject<Int, TestError>!
    private var subscription: AnyCancellable?
    private var value: Int?
    private var error: TestError?
    private var finished: Bool?
    
    private lazy var completionHandler: () -> Void = { [weak self] in
        self?.finished = true
    }
    
    private lazy var failureHandler: (TestError) -> Void = { [weak self] in
        self?.error = $0
    }
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()
        
        source = .init()
        value = nil
        subscription = nil
        error = nil
        finished = nil
    }
    
    // MARK: - Tests
    
    func test_sinkReceiveValue() {
        subscription = source.sinkValue { [weak self] in
            self?.value = $0
        }
        
        let testValue = 10
        source.send(testValue)
        XCTAssertEqual(value, testValue)
        XCTAssertNil(error)
        XCTAssertNil(finished)
        
        source.send(completion: .finished)
        XCTAssertEqual(value, testValue)
        XCTAssertNil(error)
        XCTAssertNil(finished)
    }
    
    func test_sinkReceiveCompletion_finished() {
        subscription = source.sinkCompletion(completionHandler: completionHandler)
        
        source.send(completion: .finished)
        
        XCTAssertNil(value)
        XCTAssertNil(error)
        XCTAssertEqual(finished, true)
    }
    
    func test_sinkReceiveCompletion_failure() {
        subscription = source.sinkCompletion(completionHandler: completionHandler)
        
        source.send(completion: .failure(TestError.test))
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
    func test_sinkReceiveCompletion_value() {
        subscription = source.sinkCompletion(completionHandler: completionHandler)
        
        source.send(10)
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
    func test_sinkReceiveFailure_finished() {
        subscription = source.sinkFailure(failureHandler: failureHandler)
        
        source.send(completion: .finished)
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
    func test_sinkReceiveFailure_failure() {
        subscription = source.sinkFailure(failureHandler: failureHandler)
        
        let testValue = TestError.test
        source.send(completion: .failure(testValue))
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertEqual(testValue, error)
    }
    
    func test_sinkReceiveFailure_value() {
        subscription = source.sinkFailure(failureHandler: failureHandler)
        
        source.send(10)
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
}
