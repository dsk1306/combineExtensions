import Combine
@testable import CombineExtensions
import XCTest

final class PrepareToOutputTests: XCTestCase {
    
    // MARK: - Properties
    
    private var cancelable1: Cancellable?
    private var cancelable2: Cancellable?
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()

        cancelable1 = nil
        cancelable2 = nil
    }
    
    // MARK: - Tests
    
    func test_thread() {
        let expectation1 = expectation(description: "\(#function)_1")
        let expectation2 = expectation(description: "\(#function)_2")
        
        let subject = PassthroughRelay<Void>()
        
        let subscription = subject.receive(on: DispatchQueue.global())
        
        cancelable1 = subscription
            .sinkValue {
                XCTAssertFalse(Thread.isMainThread)
                expectation1.fulfill()
            }
        cancelable2 = subscription
            .prepareToOutput()
            .sinkValue {
                XCTAssertTrue(Thread.isMainThread)
                expectation2.fulfill()
            }
        
        subject.accept()
        wait(for: [expectation1, expectation2], timeout: TestConstant.expectationTimeout)
    }
    
}
