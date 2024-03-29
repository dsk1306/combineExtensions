import Combine
@testable import CombineExtensions
import XCTest

final class CombineCancellableTests: XCTestCase {
    
    // MARK: - Typealiases
    
    private typealias Source = PassthroughSubject<Int, TestError>
    
    // MARK: - Properties
    
    private var cancellable: CombineCancellable!
    private var source1: Source!
    private var source2: Source!
    private var source3: Source!
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()
        
        cancellable = .init()
        source1 = .init()
        source2 = .init()
        source3 = .init()
    }
    
    // MARK: - Tests
    
    func test_deallocate() {
        var source1Cancelled = false
        var source2Cancelled = false
        var source3Cancelled = false
        
        cancellable {
            source1
                .handleCancel { source1Cancelled = true }
                .dummySink()
            source2
                .handleCancel { source2Cancelled = true }
                .dummySink()
            source3
                .handleCancel { source3Cancelled = true }
                .dummySink()
        }
        
        cancellable = nil
        XCTAssertTrue(source1Cancelled)
        XCTAssertTrue(source2Cancelled)
        XCTAssertTrue(source3Cancelled)
    }
    
    func test_cancel() {
        var source1Cancelled = false
        var source2Cancelled = false
        var source3Cancelled = false
        
        cancellable {
            source1
                .handleCancel { source1Cancelled = true }
                .dummySink()
            source2
                .handleCancel { source2Cancelled = true }
                .dummySink()
            source3
                .handleCancel { source3Cancelled = true }
                .dummySink()
        }
        
        cancellable.cancel()
        XCTAssertTrue(source1Cancelled)
        XCTAssertTrue(source2Cancelled)
        XCTAssertTrue(source3Cancelled)
    }
    
}

// MARK: - Publisher Extension

private extension Publisher {
    
    func dummySink() -> AnyCancellable {
        sink(receiveCompletion: { _ in }, receiveValue: { _ in })
    }
    
    func handleCancel(cancelHandler: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveCancel: cancelHandler)
    }
    
}
