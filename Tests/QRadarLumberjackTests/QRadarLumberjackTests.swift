import XCTest
@testable import QRadarLumberjack

final class QRadarLumberjackTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(QRadarLumberjack().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
