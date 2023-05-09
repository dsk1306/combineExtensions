import Combine
import CombineExtensions
import Foundation
import XCTest

final class AsyncSinkTests: XCTestCase {

    // MARK: - Properties

    private var subscription: AnyCancellable?
    private var value: Int?
    private var error: TestError?
    private var finished: Bool?

    private var source = PassthroughSubject<Int, TestError>()
    private var neverFailureSource = PassthroughSubject<Int, Never>()

    // MARK: - Base Class

    override func setUp() {
        super.setUp()

        value = nil
        subscription = nil
        error = nil
        finished = nil

        source = PassthroughSubject()
        neverFailureSource = PassthroughSubject()
    }

    // MARK: - Tests

    func test_sink_completion() throws {
        let sinkExpectation = expectation(description: #function)

        subscription = source
            .sink(
                receiveCompletion: { [weak self] in
                    self?.handle(completion: $0)
                },
                receiveValue: { [weak self] in
                    await self?.assign(value: $0, expectation: sinkExpectation)
                }
            )

        source.send(Constant.value)
        wait(for: sinkExpectation)

        XCTAssertNil(error)
        XCTAssertNil(finished)
        XCTAssertEqual(value, Constant.value)

        source.send(completion: .finished)

        XCTAssertNil(error)
        XCTAssertTrue(finished ?? false)
        XCTAssertEqual(value, Constant.value)
    }

    func test_sink_error() throws {
        let sinkExpectation = expectation(description: #function)

        subscription = source
            .sink(
                receiveCompletion: { [weak self] in
                    self?.handle(completion: $0)
                },
                receiveValue: { [weak self] in
                    await self?.assign(value: $0, expectation: sinkExpectation)
                }
            )

        source.send(Constant.value)
        wait(for: sinkExpectation)

        XCTAssertNil(error)
        XCTAssertNil(finished)
        XCTAssertEqual(value, Constant.value)

        source.send(completion: .failure(.test))

        XCTAssertNil(finished)
        XCTAssertEqual(error, .test)
        XCTAssertEqual(value, Constant.value)
    }

    func test_sink_neverFailure() {
        let sinkExpectation = expectation(description: #function)

        subscription = neverFailureSource.sink { [weak self] in
            await self?.assign(value: $0, expectation: sinkExpectation)
        }

        neverFailureSource.send(Constant.value)
        wait(for: sinkExpectation)

        XCTAssertNil(error)
        XCTAssertNil(finished)
        XCTAssertEqual(value, Constant.value)
    }
    
}

// MARK: - Helpers

private extension AsyncSinkTests {

    func assign(value: Int, expectation: XCTestExpectation) async {
        do {
            try await Task.sleep(nanoseconds: 500000000)
            self.value = value
        } catch {
            self.error = .other(error)
        }
        expectation.fulfill()
    }

    func handle(completion: Subscribers.Completion<TestError>) {
        switch completion {
        case .finished:
            finished = true
        case .failure(let failure):
            error = failure
        }
    }

}

// MARK: - Constants

private extension AsyncSinkTests {

    enum Constant {

        static let value = 10

    }

}
