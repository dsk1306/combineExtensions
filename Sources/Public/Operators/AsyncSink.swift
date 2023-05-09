import Combine
import Foundation

public extension Publisher where Failure == Never {

    func sink(receiveValue: @escaping (Output) async -> Void) -> AnyCancellable {
        sink { value in
            Task {
                await receiveValue(value)
            }
        }
    }

}
