import Combine
import Foundation

public extension Publisher {

    func sink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) async -> Void
    ) -> AnyCancellable {
        sink(
            receiveCompletion: receiveCompletion,
            receiveValue: { output in
                Task {
                    await receiveValue(output)
                }
            }
        )
    }

    func sinkValue(valueHandler: @escaping (Output) async -> Void) -> AnyCancellable {
        sink(
            receiveCompletion: { _ in },
            receiveValue: { output in
                Task {
                    await valueHandler(output)
                }
            }
        )
    }

}

public extension Publisher where Failure == Never {

    func sink(receiveValue: @escaping (Output) async -> Void) -> AnyCancellable {
        sink { value in
            Task {
                await receiveValue(value)
            }
        }
    }

}
