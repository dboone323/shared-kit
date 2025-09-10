import XCTest
@testable import SharedKit

final class AppLoggerTests: XCTestCase {
    func testLogPrefixesMessage() throws {
        XCTAssertEqual(AppLogger.log("hello"), "[SharedKit] hello")
    }
}
