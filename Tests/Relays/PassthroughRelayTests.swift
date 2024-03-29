import Combine
@testable import CombineExtensions
import XCTest

final class PassthroughRelayTests: XCTestCase {
    
    // MARK: - Properties
    
    private var relay: PassthroughRelay<String>!
    private var values = [String]()
    private var cancellable = CombineCancellable()
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()

        relay = .init()
        cancellable = .init()
        values = []
    }
    
    // MARK: - Tests
    
    func test_finishesOnDeinit() {
        var completed = false

        relay
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { _ in }
            )
            .store(in: cancellable)
        
        XCTAssertFalse(completed)

        relay = nil
        XCTAssertTrue(completed)
    }
    
    func test_noReplay() {
        relay.accept("these")
        relay.accept("values")
        relay.accept("shouldnt")
        relay.accept("be")
        relay.accept("forwaded")
        
        relay
            .sink { [weak self] in self?.values.append($0) }
            .store(in: cancellable)
        
        XCTAssertEqual(values, [])
        
        relay.accept("yo")
        XCTAssertEqual(values, ["yo"])
        
        relay.accept("sup")
        XCTAssertEqual(values, ["yo", "sup"])
        
        var secondInitial: String?
        _ = relay.sink { secondInitial = $0 }
        XCTAssertNil(secondInitial)
    }
    
    func test_voidAccept() {
        let voidRelay = PassthroughRelay<Void>()
        var count = 0
        
        voidRelay
            .sink { count += 1 }
            .store(in: cancellable)
        
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        
        XCTAssertEqual(count, 5)
    }
    
    func test_subscribePublisher() {
        var completed = false

        relay
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { [weak self] in self?.values.append($0) }
            )
            .store(in: cancellable)
        
        ["1", "2", "3"]
            .publisher
            .subscribe(relay)
            .store(in: cancellable)
        
        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["1", "2", "3"])
    }
    
    func test_subscribeRelay_passthroughs() {
        var completed = false
        
        let input = PassthroughRelay<String>()
        let output = PassthroughRelay<String>()
        
        input
            .subscribe(output)
            .store(in: cancellable)
        output
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { [weak self] in self?.values.append($0) }
            )
            .store(in: cancellable)
        
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
            .store(in: cancellable)
        output
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { [weak self] in self?.values.append($0) }
            )
            .store(in: cancellable)
        
        input.accept("1")
        input.accept("2")
        input.accept("3")
        
        XCTAssertFalse(completed)
        XCTAssertEqual(values, ["initial", "1", "2", "3"])
    }
    
}
