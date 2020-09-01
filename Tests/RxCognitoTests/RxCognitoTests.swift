import XCTest
@testable import RxCognito

final class RxCognitoTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RxCognito().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
