import XCTest
import Combine
import CombineExtensions

final class CurrentValueRelayTests: XCTestCase {
    
    // MARK: - Properties
    
    private var relay: CurrentValueRelay<String>?
    private var values = [String]()
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()
        
        relay = CurrentValueRelay("initial")
        subscriptions = .init()
        values = []
    }
    
    // MARK: - Tests
    
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
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { _ in }
            )
            .store(in: &subscriptions)
        
        XCTAssertEqual(relay?.value, "initial")
        XCTAssertFalse(completed)
        
        relay = nil
        XCTAssertTrue(completed)
    }
    
    func test_voidAccept() {
        let voidRelay = CurrentValueRelay<Void>(())
        var count = 0
        
        voidRelay
            .sink(receiveValue: { count += 1 })
            .store(in: &subscriptions)
        
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        voidRelay.accept()
        
        XCTAssertEqual(count, 6)
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
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { self.values.append($0) }
            )
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
    
    func test_subscribeRelay_passthroughToCurrentValue() {
        var completed = false
        
        let input = PassthroughRelay<String>()
        let output = CurrentValueRelay<String>("initial")
        
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
    
    func test_storedObjectIsDeallocated_afterCancellables() {
        
        final class ContainerClass {
            
            static var receivedCompletion = false
            static var receivedCancel = false
            
            var cancellables = Set<AnyCancellable>()
            let relay = CurrentValueRelay(StoredObject())
            
            init() {
                relay
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
            
        }
        
        var container: ContainerClass? = ContainerClass()
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(StoredObject.storedObjectReleased)
        
        container = nil
        XCTAssertTrue(StoredObject.storedObjectReleased)
        XCTAssertNil(container)
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertTrue(ContainerClass.receivedCancel)
    }
    
    func test_storedObjectIsDeallocated_beforeCancellables() {
        
        final class ContainerClass {
            
            static var receivedCompletion = false
            static var receivedCancel = false
            
            let relay = CurrentValueRelay(StoredObject())
            var cancellables = Set<AnyCancellable>()
            
            init() {
                relay
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables)
            }
            
        }
        
        var container: ContainerClass? = ContainerClass()
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(StoredObject.storedObjectReleased)
        
        container = nil
        XCTAssertTrue(StoredObject.storedObjectReleased)
        XCTAssertNil(container)
        XCTAssertTrue(ContainerClass.receivedCompletion)
        XCTAssertFalse(ContainerClass.receivedCancel)
    }
    
    func test_bothStoredObjectsAreDeallocated_beforeCancellables() {
        
        final class ContainerClass {
            
            static var receivedCompletion = false
            static var receivedCancel = false
            
            let relay = CurrentValueRelay(StoredObject())
            let relay2 = CurrentValueRelay(StoredObject2())
            var cancellables: Set<AnyCancellable>? = Set<AnyCancellable>()
            
            init() {
                relay
                    .withLatestFrom(relay2)
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables!)
            }
            
        }
        
        var container: ContainerClass? = ContainerClass()
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(StoredObject.storedObjectReleased)
        XCTAssertFalse(StoredObject2.storedObjectReleased)
        
        container = nil
        XCTAssertTrue(StoredObject.storedObjectReleased)
        XCTAssertTrue(StoredObject2.storedObjectReleased)
        XCTAssertNil(container)
    }
    
    func test_bothStoredObjectsAreDeallocated_afterCancellables() {
        
        final class ContainerClass {
            
            static var receivedCompletion = false
            static var receivedCancel = false
            
            var cancellables: Set<AnyCancellable>? = Set<AnyCancellable>()
            let relay = CurrentValueRelay(StoredObject())
            let relay2 = CurrentValueRelay(StoredObject2())
            
            init() {
                relay
                    .withLatestFrom(relay2)
                    .handleEvents(receiveCancel: {
                        Self.receivedCancel = true
                    })
                    .sink(
                        receiveCompletion: { _ in
                            Self.receivedCompletion = true
                        },
                        receiveValue: { _ in }
                    )
                    .store(in: &cancellables!)
            }
            
        }
        
        var container: ContainerClass? = ContainerClass()
        XCTAssertFalse(ContainerClass.receivedCompletion)
        XCTAssertFalse(StoredObject.storedObjectReleased)
        XCTAssertFalse(StoredObject2.storedObjectReleased)
        
        container = nil
        XCTAssertTrue(StoredObject.storedObjectReleased)
        XCTAssertTrue(StoredObject2.storedObjectReleased)
        XCTAssertNil(container)
    }
    
}

// MARK: - StoredObject

private extension CurrentValueRelayTests {
    
    final class StoredObject {
        
        static var storedObjectReleased = false
        
        let value = 10
        
        init() {
            Self.storedObjectReleased = false
        }
        
        deinit {
            Self.storedObjectReleased = true
        }
        
    }
    
    final class StoredObject2 {
        
        static var storedObjectReleased = false
        
        let value = 20
        
        init() {
            Self.storedObjectReleased = false
        }
        
        deinit {
            Self.storedObjectReleased = true
        }
        
    }
    
}
