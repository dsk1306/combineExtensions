#if !os(watchOS)
import XCTest
import Combine
import CombineExtensions

final class AssignOwnershipTests: XCTestCase {

    var subscription: AnyCancellable!
    var value1 = 0
    var value2 = 0
    var value3 = 0
    var subject: PassthroughSubject<Int, Never>!

    override func setUp() {
        super.setUp()

        subscription = nil
        subject = PassthroughSubject<Int, Never>()
        value1 = 0
        value2 = 0
        value3 = 0
    }

    func test_weakOwnership() {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value1, on: self, ownership: .weak)
        subject.send(10)
        XCTAssertEqual(initialRetainCount, CFGetRetainCount(self))

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .weak)
        subject.send(15)
        XCTAssertEqual(initialRetainCount, CFGetRetainCount(self))

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, and: \.value3, on: self, ownership: .weak)
        subject.send(20)
        XCTAssertEqual(initialRetainCount, CFGetRetainCount(self))
    }

    func test_unownedOwnership() {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value1, on: self, ownership: .unowned)
        subject.send(10)
        XCTAssertEqual(initialRetainCount, CFGetRetainCount(self))

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .unowned)
        subject.send(15)
        XCTAssertEqual(initialRetainCount, CFGetRetainCount(self))

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, and: \.value3, on: self, ownership: .unowned)
        subject.send(20)
        XCTAssertEqual(initialRetainCount, CFGetRetainCount(self))
    }

    func test_strongOwnership() {
        let initialRetainCount = CFGetRetainCount(self)

        subscription = subject
            .assign(to: \.value1, on: self, ownership: .strong)
        subject.send(10)
        XCTAssertEqual(initialRetainCount + 1, CFGetRetainCount(self))

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .strong)
        subject.send(15)
        XCTAssertEqual(initialRetainCount + 2, CFGetRetainCount(self))

        subscription = subject
            .assign(to: \.value1, on: self, and: \.value2, on: self, and: \.value3, on: self, ownership: .strong)
        subject.send(20)
        XCTAssertEqual(initialRetainCount + 3, CFGetRetainCount(self))
    }

}
#endif
