import XCTest

extension XCTestCase {

    func wait(
        for expectation: XCTestExpectation,
        timeout: TimeInterval = TestConstant.expectationTimeout
    ) {
        wait(for: [expectation], timeout: timeout)
    }

}
