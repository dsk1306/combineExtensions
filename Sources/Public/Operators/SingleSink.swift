import Combine
import Foundation

public extension Publisher {

  /// Attaches a subscriber with closure-based behavior.
  /// - Parameter valueHandler: The closure to execute on completion.
  /// - Returns: A cancellable instance, which you use when you end assignment of the received value.
  /// Deallocation of the result will tear down the subscription stream.
  func sinkValue(valueHandler: @escaping ((Output) -> Void)) -> AnyCancellable {
    sink(receiveCompletion: { _ in }, receiveValue: valueHandler)
  }

  /// Attaches a subscriber with async closure-based behavior.
  /// - Parameter valueHandler: The async closure to execute on completion.
  /// - Returns: A cancellable instance, which you use when you end assignment of the received value.
  /// Deallocation of the result will tear down the subscription stream.
  func sinkValue(valueHandler: @escaping ((Output) async -> Void)) -> AnyCancellable {
    sink(
      receiveCompletion: { _ in },
      receiveValue: { output in
        Task {
          await valueHandler(output)
        }
      }
    )
  }

  /// Attaches a subscriber with closure-based behavior.
  /// - Parameter completionHandler: The closure to execute on completion.
  /// - Returns: A cancellable instance, which you use when you end assignment of the received value.
  /// Deallocation of the result will tear down the subscription stream.
  func sinkCompletion(completionHandler: @escaping (() -> Void)) -> AnyCancellable {
    sink(
      receiveCompletion: {
        switch $0 {
        case .failure:
          break
        case .finished:
          completionHandler()
        }
      },
      receiveValue: { _ in }
    )
  }

  /// Attaches a subscriber with closure-based behavior.
  /// - Parameter failureHandler: The closure to execute on failure.
  /// - Returns: A cancellable instance, which you use when you end assignment of the received value.
  /// Deallocation of the result will tear down the subscription stream.
  func sinkFailure(failureHandler: @escaping (Failure) -> Void) -> AnyCancellable {
    sink(
      receiveCompletion: {
        switch $0 {
        case .failure(let error):
          failureHandler(error)
        case .finished:
          break
        }
      },
      receiveValue: { _ in }
    )
  }

}
