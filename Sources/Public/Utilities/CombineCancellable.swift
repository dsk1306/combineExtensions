import Combine
import Foundation

final public class CombineCancellable {

  // MARK: - Private Properties

  private var cancellable = Set<AnyCancellable>()

  // MARK: - Initialization

  public init() {}

}

// MARK: - Public Methods

public extension CombineCancellable {

  func callAsFunction(@ResultBuilder<AnyCancellable> disposables: () -> [AnyCancellable]) {
    disposables().forEach { $0.store(in: &cancellable) }
  }

  func store(_ anyCancellable: AnyCancellable) {
    anyCancellable.store(in: &cancellable)
  }

  func cancel() {
    cancellable.forEach { $0.cancel() }
    cancellable.removeAll()
  }

}

// MARK: - AnyCancellable Extension

public extension AnyCancellable {

  func store(in bag: CombineCancellable) {
    bag.store(self)
  }

}
