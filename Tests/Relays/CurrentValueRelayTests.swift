#if !os(watchOS)
import XCTest
import Combine
import CombineExt

class CurrentValueRelayTests: XCTestCase {

    private var relay: CurrentValueRelay<String>?
    private var values = [String]()
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()

        relay = CurrentValueRelay("initial")
        subscriptions = .init()
        values = []
    }

    func test_valueGetter() {
        XCTAssertEqual(relay?.value, "initial")

        relay?.accept("second")
        XCTAssertEqual(relay?.value, "second")

        relay?.accept("third")
        XCTAssertEqual(relay?.value, "third")
    }

    func test_finishesOnDeinit() {
        var completed = false

        relay?
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        XCTAssertEqual(relay?.value, "initial")

        XCTAssertFalse(completed)

        relay = nil
        XCTAssertTrue(completed)
    }

    func test_replaysCurrentValue() {
        relay?
            .sink(receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        XCTAssertEqual(values, ["initial"])

        relay?.accept("yo")
        XCTAssertEqual(values, ["initial", "yo"])

        var secondInitial: String?
        _ = relay?.sink(receiveValue: { secondInitial = $0 })
        XCTAssertEqual(secondInitial, "yo")
    }

    func test_subscribePublisher() {
        var completed = false
        relay?
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        ["1", "2", "3"]
            .publisher
            .subscribe(relay!)
            .store(in: &subscriptions)

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }

    func test_subscribeRelay_CurrentValues() {
        var completed = false

        let input = CurrentValueRelay<String>("initial")
        let output = CurrentValueRelay<String>("initial")

        input
            .subscribe(output)
            .store(in: &subscriptions)
        output
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        input.accept("1")
        input.accept("2")
        input.accept("3")

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }

    func test_subscribeRelay_passthroughToCurrentValue() {
        var completed = false

        let input = PassthroughRelay<String>()
        let output = CurrentValueRelay<String>("initial")

        input
            .subscribe(output)
            .store(in: &subscriptions)
        output
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        input.accept("1")
        input.accept("2")
        input.accept("3")

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }

}
#endif
