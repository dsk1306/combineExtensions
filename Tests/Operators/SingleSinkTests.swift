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
        
        source = PassthroughSubject<Int, TestError>()
        value = nil
        subscription = nil
        error = nil
        finished = nil
    }
    
    // MARK: - Tests
    
    func test_sinkReceiveValue() {
        subscription = source
            .sinkValue { [weak self] in self?.value = $0 }
        
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
    
    func test_sinkReceiveValue_async() throws {
        let expectation1 = expectation(description: "\(#function)")
        
        subscription = source
            .sinkValue { [weak self] in
                do {
                    try await self?.asyncAssign(value: $0)
                } catch {
                    self?.error = .other(error)
                }
                expectation1.fulfill()
            }
        
        let testValue = 10
        source.send(testValue)
        wait(for: [expectation1], timeout: Constant.timeout)
        
        XCTAssertEqual(value, testValue)
        XCTAssertNil(error)
        XCTAssertNil(finished)
        
        source.send(completion: .finished)
        XCTAssertEqual(value, testValue)
        XCTAssertNil(error)
        XCTAssertNil(finished)
    }
    
    func asyncAssign(value: Int) async throws {
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
        self.value = value
    }
    
    func test_sinkReceiveCompletion_finished() {
        subscription = source
            .sinkCompletion(completionHandler: completionHandler)
        
        source.send(completion: .finished)
        
        XCTAssertNil(value)
        XCTAssertNil(error)
        XCTAssertEqual(finished, true)
    }
    
    func test_sinkReceiveCompletion_failure() {
        subscription = source
            .sinkCompletion(completionHandler: completionHandler)
        
        source.send(completion: .failure(TestError.test))
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
    func test_sinkReceiveCompletion_value() {
        subscription = source
            .sinkCompletion(completionHandler: completionHandler)
        
        source.send(10)
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
    func test_sinkReceiveFailure_finished() {
        subscription = source
            .sinkFailure(failureHandler: failureHandler)
        
        source.send(completion: .finished)
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
    func test_sinkReceiveFailure_failure() {
        subscription = source
            .sinkFailure(failureHandler: failureHandler)
        
        let testValue = TestError.test
        source.send(completion: .failure(testValue))
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertEqual(testValue, error)
    }
    
    func test_sinkReceiveFailure_value() {
        subscription = source
            .sinkFailure(failureHandler: failureHandler)
        
        source.send(10)
        
        XCTAssertNil(value)
        XCTAssertNil(finished)
        XCTAssertNil(error)
    }
    
}

// MARK: - Constants

private extension SingleSinkTests {
    
    enum Constant {
        
        static let timeout: TimeInterval = 5
        
    }
    
}

// MARK: - Test Error

private extension SingleSinkTests {
    
    enum TestError: Error, Equatable {
        
        case test
        case other(Error)
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.test, .test):
                return true
            case (.other(let lhsError), .other(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
        
    }
    
}
