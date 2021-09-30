#if !os(watchOS)
import XCTest
import Combine
import CombineExtensions

final class PassthroughRelayTests: XCTestCase {

    private var relay: PassthroughRelay<String>?
    private var values = [String]()
    private var subscriptions = Set<AnyCancellable>()

    override func setUp() {
        relay = PassthroughRelay<String>()
        subscriptions = .init()
        values = []
    }

    func test_finishesOnDeinit() {
        var completed = false
        relay?
            .sink(receiveCompletion: { _ in completed = true },
                  receiveValue: { _ in })
            .store(in: &subscriptions)

        XCTAssertFalse(completed)
        relay = nil
        XCTAssertTrue(completed)
    }

    func test_noReplay() {
        relay?.accept("these")
        relay?.accept("values")
        relay?.accept("shouldnt")
        relay?.accept("be")
        relay?.accept("forwaded")

        relay?
            .sink(receiveValue: { self.values.append($0) })
            .store(in: &subscriptions)

        XCTAssertEqual(values, [])

        relay?.accept("yo")
        XCTAssertEqual(values, ["yo"])

        relay?.accept("sup")
        XCTAssertEqual(values, ["yo", "sup"])

        var secondInitial: String?
        _ = relay?.sink(receiveValue: { secondInitial = $0 })
        XCTAssertNil(secondInitial)
    }

    func test_voidAccept() {
        let voidRelay = PassthroughRelay<Void>()
        var count = 0

        voidRelay
            .sink(receiveValue: { count += 1 })
            .store(in: &subscriptions)

        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()

        XCTAssertEqual(count, 5)
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
        XCTAssertEqual(values, ["1", "2", "3"])
    }

    func test_subscribeRelay_passthroughs() {
        var completed = false

        let input = PassthroughRelay<String>()
        let output = PassthroughRelay<String>()

        input
            .subscribe(output)
            .store(in: &subscriptions)
        output
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { self.values.append($0) }
            )
            .store(in: &subscriptions)

        input.accept("1")
        input.accept("2")
        input.accept("3")

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["1", "2", "3"])
    }

    func test_subscribeRelay_currentValueToPassthrough() {
        var completed = false

        let input = CurrentValueRelay<String>("initial")
        let output = PassthroughRelay<String>()

        input
            .subscribe(output)
            .store(in: &subscriptions)
        output
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { self.values.append($0) }
            )
            .store(in: &subscriptions)

        input.accept("1")
        input.accept("2")
        input.accept("3")

        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }

}
#endif
