@testable import SharedKit
import XCTest

final class AppLoggerTests: XCTestCase {
    func testLogPrefixesMessage() throws {
        XCTAssertEqual(AppLogger.log("hello"), "[SharedKit] hello")
    }
}
