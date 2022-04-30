import Combine
import Foundation

public extension Publisher {
    
    /// Erases publisher and send it output on main queue.
    func prepareToOutput() -> AnyPublisher<Output, Failure> {
        self.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
}
