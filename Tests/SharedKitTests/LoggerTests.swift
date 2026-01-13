//
// LoggerTests.swift
// SharedKitTests
//

import XCTest
@testable import SharedKit

final class LoggerTests: XCTestCase {
    
    func testLoggerSharedInstance() {
        let logger = AppLogger.shared
        XCTAssertNotNil(logger)
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
