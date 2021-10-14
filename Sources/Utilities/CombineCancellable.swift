import Combine
import Foundation

final public class CombineCancellable {

    // MARK: - Private Properties

    private var cancellable = Set<AnyCancellable>()

    public init() {}

    // MARK: - Public Methods

    public func callAsFunction(@ResultBuilder<AnyCancellable> disposables: () -> [AnyCancellable]) {
        disposables().forEach { $0.store(in: &cancellable) }
    }

    public func store(_ anyCancellable: AnyCancellable) {
        anyCancellable.store(in: &cancellable)
    }

    public func cancel() {
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
