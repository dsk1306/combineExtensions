import Combine
import CombineExtensions
import Foundation
import XCTest

final class AsyncSinkTests: XCTestCase {

    // MARK: - Properties

    private var value: Int?
    private var subscription: AnyCancellable?
    private var source = PassthroughSubject<Int, Never>()

    // MARK: - Base Class

    override func setUp() {
        super.setUp()

        value = nil
        subscription = nil
        source = PassthroughSubject()
    }

    // MARK: - Tests

    func test_receiveValue() {
        let sinkExpectation = expectation(description: #function)

        subscription = source
            .sink { [weak self] in
                await self?.updateValue(for: $0)
                sinkExpectation.fulfill()
            }

        let testValue = 10
        source.send(testValue)
        wait(for: [sinkExpectation], timeout: Constant.timeout)

        XCTAssertEqual(value, testValue)
    }
    
}

// MARK: - Helpers

private extension AsyncSinkTests {

    func updateValue(for value: Int) async {
        try! await Task.sleep(nanoseconds: 500000000)
        self.value = value
    }

}

// MARK: - Constants

private extension AsyncSinkTests {

    enum Constant {

        static let timeout: TimeInterval = 5

    }

}
