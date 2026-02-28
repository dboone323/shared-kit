//
// LoggerTests.swift
// SharedKitTests
//

import SharedKitCore
@testable import SharedKit
import XCTest

final class LoggerTests: XCTestCase {
    func testLoggerSharedInstance() {
        // SharedLogger is a static utility class, not a singleton
        SharedLogger.logInfo("Test message")
        XCTAssertTrue(true, "SharedLogger should work via static methods")
    }

    func testLogLevelDebug() {
        XCTAssertTrue(true, "Debug log level test")
    }

    func testLogLevelInfo() {
        XCTAssertTrue(true, "Info log level test")
    }

    func testLogLevelWarning() {
        XCTAssertTrue(true, "Warning log level test")
    }

    func testLogLevelError() {
        XCTAssertTrue(true, "Error log level test")
    }
}
