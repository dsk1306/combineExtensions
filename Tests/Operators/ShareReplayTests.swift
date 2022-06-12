import Combine
import CombineExtensions
import XCTest

final class ShareReplayTests: XCTestCase {

  // MARK: - Properties

  private var subscriptions = Set<AnyCancellable>()

  // MARK: - Tests

  func test_sharing_noReplay() {
    var subscribeCount = 0

    let publisher = Publishers.Create<Int, Never> { subscriber in
      subscribeCount += 1
      subscriber.send(1)
      subscriber.send(2)
      subscriber.send(3)
      subscriber.send(completion: .finished)

      return AnyCancellable { }
    }
    .share(replay: 0)

    publisher
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)

    publisher
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)

    publisher
      .sink(receiveValue: { _ in })
      .store(in: &subscriptions)

    XCTAssertEqual(subscribeCount, 1)
  }

  func test_sharing_singleReplay() {
    let subject = CurrentValueSubject<Int, Never>(1)

    let publisher = subject
      .share(replay: 1)

    var results = [Int]()

    publisher
      .sink(receiveValue: { results.append($0) })
      .store(in: &subscriptions)

    subject.send(2)

    XCTAssertEqual(results, [1, 2])
  }

  func test_sharing_manyReplay() {
    let subject = PassthroughSubject<Int, Never>()

    var results1 = [Int]()
    var results2 = [Int]()

    let publisher = subject
      .share(replay: 3)

    publisher
      .sink(receiveValue: { results1.append($0) })
      .store(in: &subscriptions)

    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)

    publisher
      .sink(receiveValue: { results2.append($0) })
      .store(in: &subscriptions)

    XCTAssertEqual(results1, [1, 2, 3, 4])
    XCTAssertEqual(results2, [2, 3, 4])
  }

  func test_sharing_finishedEvent() {
    let subject = PassthroughSubject<Int, Never>()

    var results1 = [Int]()
    var completions1 = [Subscribers.Completion<Never>]()

    var results2 = [Int]()
    var completions2 = [Subscribers.Completion<Never>]()

    let publisher = subject
      .share(replay: 3)

    publisher
      .sink(
        receiveCompletion: { completions1.append($0) },
        receiveValue: { results1.append($0) }
      )
      .store(in: &subscriptions)

    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(completion: .finished)

    publisher
      .sink(
        receiveCompletion: { completions2.append($0) },
        receiveValue: { results2.append($0) }
      )
      .store(in: &subscriptions)

    XCTAssertEqual(results1, [1, 2, 3, 4])
    XCTAssertEqual(completions1, [.finished])

    XCTAssertEqual(results2, [2, 3, 4])
    XCTAssertEqual(completions2, [.finished])
  }

  func test_sharing_errorEvent() {
    let subject = PassthroughSubject<Int, AnError>()

    var results1 = [Int]()
    var completions1 = [Subscribers.Completion<AnError>]()

    var results2 = [Int]()
    var completions2 = [Subscribers.Completion<AnError>]()

    let publisher = subject
      .share(replay: 3)

    publisher
      .sink(
        receiveCompletion: { completions1.append($0) },
        receiveValue: { results1.append($0) }
      )
      .store(in: &subscriptions)

    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(completion: .failure(.someError))

    publisher
      .sink(
        receiveCompletion: { completions2.append($0) },
        receiveValue: { results2.append($0) }
      )
      .store(in: &subscriptions)

    XCTAssertEqual(results1, [1, 2, 3, 4])
    XCTAssertEqual(completions1, [.failure(.someError)])

    XCTAssertEqual(results2, [2, 3, 4])
    XCTAssertEqual(completions2, [.failure(.someError)])
  }

  func test_sharing_noClassBasedPublisherRetain() {
    var results = [Int]()
    var completions = [Subscribers.Completion<Never>]()

    var source: PassthroughSubject? = PassthroughSubject<Int, Never>()
    weak var weakSource = source

    var stream = source?.share(replay: 1)

    stream?
      .sink(
        receiveCompletion: { completions.append($0) },
        receiveValue: { results.append($0) }
      )
      .store(in: &subscriptions)

    source?.send(1)
    source?.send(completion: .finished)

    subscriptions.forEach({ $0.cancel() })
    stream = nil
    source = nil

    XCTAssertEqual(results, [1])
    XCTAssertEqual(completions, [.finished])
    XCTAssertNil(weakSource)
  }

  func test_finishWithNoReplay() {
    let subject = PassthroughSubject<Int, Never>()

    var results = [Int]()
    var completions = [Subscribers.Completion<Never>]()

    let publisher = subject
      .share(replay: 1)

    publisher
      .sink(
        receiveCompletion: { completions.append($0) },
        receiveValue: { results.append($0) }
      )
      .store(in: &subscriptions)

    subject.send(completion: .finished)
    subject.send(1)

    XCTAssertTrue(results.isEmpty)
    XCTAssertEqual(completions, [.finished])
  }

  func test_errorWithNoReplay() {
    let subject = PassthroughSubject<Int, AnError>()

    var results = [Int]()
    var completions = [Subscribers.Completion<AnError>]()

    let publisher = subject
      .share(replay: 1)

    publisher
      .sink(
        receiveCompletion: { completions.append($0) },
        receiveValue: { results.append($0) }
      )
      .store(in: &subscriptions)

    subject.send(completion: .failure(.someError))
    subject.send(1)

    XCTAssertTrue(results.isEmpty)
    XCTAssertEqual(completions, [.failure(.someError)])
  }

  func test_sequentialUpstreamWithShareReplay() {
    let publisher = Just(1)
      .eraseToAnyPublisher()
      .share(replay: 1)

    var valueReceived = false
    var finishedReceived = false

    Publishers.Zip(publisher, publisher)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finishedReceived = true
          case let .failure(error):
            XCTFail("Unexpected completion - failure: \(error).")
          }
        },
        receiveValue: { leftValue, rightValue in
          XCTAssertEqual(leftValue, 1)
          XCTAssertEqual(rightValue, 1)

          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finishedReceived)
  }

}

// MARK: - AnError

private extension ShareReplayTests {

  enum AnError: Error {

    case someError

  }

}
