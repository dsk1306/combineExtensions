#if !os(watchOS)
import XCTest
import Combine
import CombineExtensions

final class AssignOwnershipTests: XCTestCase {

  // MARK: - Properties

  var subscription: AnyCancellable!
  var value1 = 0
  var value2 = 0
  var value3 = 0
  var subject: PassthroughSubject<Int, Never>!

  // MARK: - Base Class

  override func setUp() {
    super.setUp()

    subscription = nil
    subject = PassthroughSubject<Int, Never>()
    value1 = 0
    value2 = 0
    value3 = 0
  }

  // MARK: - Tests

  func test_weakOwnership() {
    let initialRetainCount = CFGetRetainCount(self)

    subscription = subject
      .assign(to: \.value1, on: self, ownership: .weak)
    subject.send(10)
    let resultRetainCount1 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount, resultRetainCount1)

    subscription = subject
      .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .weak)
    subject.send(15)
    let resultRetainCount2 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount, resultRetainCount2)

    subscription = subject
      .assign(
        to: \.value1,
        on: self,
        and: \.value2,
        on: self,
        and: \.value3,
        on: self,
        ownership: .weak
      )
    subject.send(20)
    let resultRetainCount3 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount, resultRetainCount3)
  }

  func test_unownedOwnership() {
    let initialRetainCount = CFGetRetainCount(self)

    subscription = subject
      .assign(to: \.value1, on: self, ownership: .unowned)
    subject.send(10)
    let resultRetainCount1 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount, resultRetainCount1)

    subscription = subject
      .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .unowned)
    subject.send(15)
    let resultRetainCount2 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount, resultRetainCount2)

    subscription = subject
      .assign(
        to: \.value1,
        on: self,
        and: \.value2,
        on: self,
        and: \.value3,
        on: self,
        ownership: .unowned
      )
    subject.send(20)
    let resultRetainCount3 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount, resultRetainCount3)
  }

  func test_strongOwnership() {
    let initialRetainCount = CFGetRetainCount(self)

    subscription = subject
      .assign(to: \.value1, on: self, ownership: .strong)
    subject.send(10)
    let resultRetainCount1 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount + 1, resultRetainCount1)

    subscription = subject
      .assign(to: \.value1, on: self, and: \.value2, on: self, ownership: .strong)
    subject.send(15)
    let resultRetainCount2 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount + 2, resultRetainCount2)

    subscription = subject
      .assign(
        to: \.value1,
        on: self,
        and: \.value2,
        on: self,
        and: \.value3,
        on: self,
        ownership: .strong
      )
    subject.send(20)
    let resultRetainCount3 = CFGetRetainCount(self)
    XCTAssertEqual(initialRetainCount + 3, resultRetainCount3)
  }

}
#endif
