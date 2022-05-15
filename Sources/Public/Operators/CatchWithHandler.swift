import Combine
import Foundation

public extension Publisher {

  func `catch`(errorHandler: @escaping (Error) -> Void) -> AnyPublisher<Output, Never> {
    // swiftlint:disable:next trailing_closure
    map { value -> Output? in value }
      .handleEvents(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          errorHandler(error)

        case .finished:
          break
        }
      })
      .catch { _ in Just(nil) }
      .compactMap { $0 }
      .eraseToAnyPublisher()
  }

}
