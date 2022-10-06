import Combine
import CombineExtensions
import Foundation
import XCTest

final class MapToValueTests: XCTestCase {
    
    // MARK: - Properties
    
    private var subscription: AnyCancellable!
    
    // MARK: - Base Class
    
    override func setUp() {
        super.setUp()
        
        subscription = nil
    }
    
    // MARK: - Tests
    
    func test_mapTo_constantValue() {
        let subject = PassthroughSubject<Int, Never>()
        var result: Int? = nil
        
        subscription = subject
            .mapToValue(2)
            .sink(receiveValue: { result = $0 })
        
        subject.send(1)
        XCTAssertEqual(result, 2)
    }
    
    func test_mapTo_withMultipleElements() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        
        let subject = PassthroughSubject<Int, Never>()
        
        subscription = subject
            .mapToValue("hello")
            .sink { element in
                XCTAssertEqual(element, "hello")
                expectation.fulfill()
            }
        
        subject.send(1)
        subject.send(2)
        subject.send(1)
        
        wait(for: [expectation], timeout: 3)
    }
    
    func test_mapTo_void() {
        let expectation = XCTestExpectation()
        let subject = PassthroughSubject<Int, Never>()
        
        subscription = subject
            .mapToValue(Void())
            .sink { element in
                XCTAssertTrue(type(of: element) == Void.self)
                
                expectation.fulfill()
            }
        
        subject.send(1)
        
        wait(for: [expectation], timeout: 3)
    }
    
    func test_mapTo_optionalType() {
        let subject = PassthroughSubject<Int, Never>()
        let value: String? = nil
        
        var result: String? = nil
        
        subscription = subject
            .mapToValue(value)
            .sink(receiveValue: { result = $0 })
        
        subject.send(1)
        XCTAssertEqual(result, nil)
    }
    
    /// Checks if regular map functions complies and works as expected.
    func test_mapTo_nameCollision() {
        let fooSubject = PassthroughSubject<Int, Never>()
        let barSubject = PassthroughSubject<Int, Never>()
        
        var result: String? = nil
        
        let combinedPublisher = Publishers.CombineLatest(fooSubject, barSubject)
            .map { fooItem, barItem in
                fooItem * barItem
            }
        
        subscription = combinedPublisher
            .map { "\($0)" }
            .sink(receiveValue: { result = $0 })
        
        fooSubject.send(5)
        barSubject.send(6)
        XCTAssertEqual(result, "30")
    }
    
    func test_mapToVoid_withMultipleEvents() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        
        let subject = PassthroughSubject<String, Never>()
        subscription = subject
            .mapToVoid()
            .sink { element in
                XCTAssertTrue(type(of: element) == Void.self)
                expectation.fulfill()
            }
        
        subject.send("test 1")
        subject.send("test 2")
        subject.send("test 3")
        
        wait(for: [expectation], timeout: 3)
    }
    
    func test_mapToVoid_withError() {
        let expectation = XCTestExpectation()
        expectation.expectedFulfillmentCount = 3
        
        enum TestError: Error {
            case example
        }
        
        let subject = PassthroughSubject<String, Error>()
        subscription = subject
            .mapToVoid()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail()
                    default:
                        break
                    }
                },
                receiveValue: {
                    expectation.fulfill()
                }
            )
        
        subject.send("test 1")
        subject.send("test 2")
        subject.send("test 3")
        subject.send(completion: .failure(TestError.example))
        
        wait(for: [expectation], timeout: 3)
    }
    
}
