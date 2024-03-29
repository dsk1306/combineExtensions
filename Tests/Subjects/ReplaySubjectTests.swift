import Combine
@testable import CombineExtensions
import XCTest

final class ReplaySubjectTests: XCTestCase {
    
    // MARK: - Properties
    
    private var demandSubscription: Subscription!
    private var cancellable = CombineCancellable()
    private var results = [Int]()

    // MARK: - Base Class

    override func setUp() {
        super.setUp()

        demandSubscription = nil
        cancellable = .init()
        results = []
    }
    
    // MARK: - Tests
    
    func test_replaysNoValues() {
        ReplaySubject<Int, Never>(bufferSize: 1)
            .sink { [weak self] in self?.results.append($0) }
            .store(in: cancellable)
        
        XCTAssertTrue(results.isEmpty)
    }
    
    func test_missedValue_emptyBuffer() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 0)

        subject.send(1)

        subject
            .sink { [weak self] in self?.results.append($0) }
            .store(in: cancellable)

        subject.send(2)

        XCTAssertEqual(results, [2])
    }
    
    func test_missedValue_singleBuffer() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 1)
        
        subject.send(1)
        
        subject
            .sink { [weak self] in self?.results.append($0) }
            .store(in: cancellable)
        
        subject.send(2)
        
        XCTAssertEqual(results, [1, 2])
    }
    
    func test_missedValue_manyBuffer() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 3)
        
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)
        
        subject
            .sink { [weak self] in self?.results.append($0) }
            .store(in: cancellable)
        
        subject.send(5)
        
        XCTAssertEqual(results, [2, 3, 4, 5])
    }
    
    func test_missedValue_manyBuffer_unfilled() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 3)
        
        subject.send(1)
        subject.send(2)
        
        subject
            .sink { [weak self] in self?.results.append($0) }
            .store(in: cancellable)
        
        subject.send(3)
        
        XCTAssertEqual(results, [1, 2, 3])
    }
    
    func test_multipleSubscribers() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 3)
        
        subject.send(1)
        subject.send(2)
        
        var results1 = [Int]()
        var results2 = [Int]()
        var results3 = [Int]()
        
        subject
            .sink { results1.append($0) }
            .store(in: cancellable)
        
        subject
            .sink { results2.append($0) }
            .store(in: cancellable)
        
        subject
            .sink { results3.append($0) }
            .store(in: cancellable)
        
        subject.send(3)
        
        XCTAssertEqual(results1, [1, 2, 3])
        XCTAssertEqual(results2, [1, 2, 3])
        XCTAssertEqual(results3, [1, 2, 3])
    }
    
    func test_completionWithMultipleSubscribers() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 3)
        
        subject.send(1)
        subject.send(2)
        subject.send(completion: .finished)
        
        var results1 = [Int]()
        var completions1 = [Subscribers.Completion<Never>]()
        
        var results2 = [Int]()
        var completions2 = [Subscribers.Completion<Never>]()
        
        var results3 = [Int]()
        var completions3 = [Subscribers.Completion<Never>]()
        
        subject
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )
            .store(in: cancellable)
        
        subject
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )
            .store(in: cancellable)
        
        subject
            .sink(
                receiveCompletion: { completions3.append($0) },
                receiveValue: { results3.append($0) }
            )
            .store(in: cancellable)
        
        subject.send(3)
        
        XCTAssertEqual(results1, [1, 2])
        XCTAssertEqual(completions1, [.finished])
        
        XCTAssertEqual(results2, [1, 2])
        XCTAssertEqual(completions2, [.finished])
        
        XCTAssertEqual(results3, [1, 2])
        XCTAssertEqual(completions3, [.finished])
    }
    
    func test_errorWithMultipleSubscribers() {
        let subject = ReplaySubject<Int, TestError>(bufferSize: 3)
        
        subject.send(1)
        subject.send(2)
        subject.send(completion: .failure(.test))
        
        var results1 = [Int]()
        var completions1 = [Subscribers.Completion<TestError>]()
        
        var results2 = [Int]()
        var completions2 = [Subscribers.Completion<TestError>]()
        
        var results3 = [Int]()
        var completions3 = [Subscribers.Completion<TestError>]()
        
        
        subject
            .sink(
                receiveCompletion: { completions1.append($0) },
                receiveValue: { results1.append($0) }
            )
            .store(in: cancellable)
        
        subject
            .sink(
                receiveCompletion: { completions2.append($0) },
                receiveValue: { results2.append($0) }
            )
            .store(in: cancellable)
        
        subject
            .sink(
                receiveCompletion: { completions3.append($0) },
                receiveValue: { results3.append($0) }
            )
            .store(in: cancellable)
        
        subject.send(3)
        
        XCTAssertEqual(results1, [1, 2])
        XCTAssertEqual(completions1, [.failure(.test)])
        
        XCTAssertEqual(results2, [1, 2])
        XCTAssertEqual(completions2, [.failure(.test)])
        
        XCTAssertEqual(results3, [1, 2])
        XCTAssertEqual(completions3, [.failure(.test)])
    }
    
    func test_valueAndCompletionPreSubscribe() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 1)
        
        subject.send(1)
        subject.send(completion: .finished)

        var completed = false
        
        subject
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { [weak self] in self?.results.append($0) }
            )
            .store(in: cancellable)
        
        XCTAssertEqual(results, [1])
        XCTAssertTrue(completed)
    }
    
    func test_noValuesReplayed_postCompletion() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 1)
        
        subject.send(1)
        subject.send(completion: .finished)
        subject.send(2)

        var completed = false
        
        subject
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { [weak self] in self?.results.append($0) }
            )
            .store(in: cancellable)
        
        XCTAssertEqual(results, [1])
        XCTAssertTrue(completed)
    }
    
    func test_noValuesReplayed_postError() {
        let subject = ReplaySubject<Int, TestError>(bufferSize: 1)
        
        subject.send(1)
        subject.send(completion: .failure(.test))
        subject.send(2)

        var completed = false
        
        subject
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { [weak self] in self?.results.append($0) }
            )
            .store(in: cancellable)
        
        XCTAssertEqual(results, [1])
        XCTAssertTrue(completed)
    }
    
    func test_respectsDemand() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 4)
        
        subject.send(1)
        subject.send(2)
        subject.send(3)
        subject.send(4)

        var completed = false
        
        let subscriber = AnySubscriber<Int, Never>(
            receiveSubscription: { [weak self] subscription in
                self?.demandSubscription = subscription
                subscription.request(.max(3))
            },
            receiveValue: { [weak self] in
                self?.results.append($0)
                return .none
            },
            receiveCompletion: { _ in completed = true }
        )
        
        subject.subscribe(subscriber)
        
        XCTAssertEqual(results, [1, 2, 3])
        XCTAssertFalse(completed)
        
        subject.send(completion: .finished)
        
        XCTAssertTrue(completed)
    }
    
    func test_doubleSubscribe() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 1)
        
        subject.send(1)
        subject.send(2)
        subject.send(completion: .finished)
        
        var results = [String]()
        var completions = [Subscribers.Completion<Never>]()
        
        let subscriber = AnySubscriber<String, Never>(
            receiveSubscription: { $0.request(.max(1)) },
            receiveValue: {
                results.append($0)
                return .none
            },
            receiveCompletion: { completions.append($0) }
        )
        
        subject
            .map { "a\($0)" }
            .subscribe(subscriber)
        
        subject
            .map { "b\($0)" }
            .subscribe(subscriber)
        
        XCTAssertEqual(["a2", "b2"], results)
        XCTAssertEqual([.finished, .finished], completions)
    }
    
    func test_removesSubscriptionsAfterCancellation() {
        let subject = ReplaySubject<Int, Never>(bufferSize: 1)
        
        var subscription1: Subscription?
        let subscriber1 = AnySubscriber<Int, Never>(
            receiveSubscription: { subscription1 = $0 }
        )
        
        var subscription2: Subscription?
        let subscriber2 = AnySubscriber<Int, Never>(
            receiveSubscription: { subscription2 = $0 }
        )
        
        XCTAssertTrue(subject.subscriptions.isEmpty)
        
        subject
            .subscribe(subscriber1)
        subject
            .subscribe(subscriber2)
        
        XCTAssertEqual(
            subject.subscriptions.map(\.combineIdentifier),
            [subscription1?.combineIdentifier, subscription2?.combineIdentifier]
        )
        
        subscription1?.cancel()
        
        XCTAssertEqual(
            subject.subscriptions.map(\.combineIdentifier),
            [subscription2?.combineIdentifier]
        )
        
        subscription2?.cancel()
        
        XCTAssertTrue(subject.subscriptions.isEmpty)
    }
    
    func testReplayOrderThreadSafety() async {
        continueAfterFailure = false
        // Loop to ensure any race condition is caught.
        for _ in 0..<5000 {
            let replaySubject = ReplaySubject<Int, Never>(bufferSize: 3)
            replaySubject.send(1)
            replaySubject.send(2)
            
            // Use tasks to create a new subscription on one thread while sending the third value on another thread.
            // The new subscription should always receive [1, 2, 3].
            await withTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTask {
                    let output: [Int] = await withCheckedContinuation { continuation in
                        var cancellable: AnyCancellable?
                        cancellable = replaySubject.collect(3).first().sink(receiveValue: { value in
                            continuation.resume(returning: value)
                            withExtendedLifetime(cancellable) { cancellable = nil }
                        })
                    }
                    
                    await MainActor.run {
                        XCTAssertEqual(output, [1, 2, 3])
                    }
                }
                
                taskGroup.addTask {
                    replaySubject.send(3)
                }
            }
        }
    }
    
}
