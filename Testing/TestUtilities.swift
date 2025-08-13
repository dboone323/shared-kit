import XCTest
import SwiftData

/// Shared testing utilities for all projects
@MainActor
class TestUtilities {
    
    /// Creates an in-memory ModelContainer for testing
    static func createTestContainer<T: PersistentModel>(for models: [T.Type]) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    /// Measures async operation performance
    static func measureAsync<T>(
        operation: String,
        timeout: TimeInterval = 10.0,
        operation: @escaping () async throws -> T
    ) async throws -> (result: T, duration: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        
        print("⏱️ \(operation) completed in \(String(format: "%.3f", duration))s")
        XCTAssertLessThan(duration, timeout, "\(operation) took too long")
        
        return (result: result, duration: duration)
    }
    
    /// Creates test data for different project types
    static func createTestTransaction() -> [String: Any] {
        return [
            "amount": 25.99,
            "description": "Test Transaction",
            "date": Date(),
            "type": "expense",
            "category": "Test Category"
        ]
    }
    
    static func createTestHabit() -> [String: Any] {
        return [
            "name": "Test Habit",
            "description": "Test habit description",
            "frequency": "daily",
            "isActive": true
        ]
    }
    
    static func createTestCodeFile() -> [String: Any] {
        return [
            "name": "TestFile.swift",
            "content": "import Foundation\n\nclass TestClass {\n    func testMethod() {\n        print(\"Hello, test!\")\n    }\n}",
            "language": "swift",
            "size": 100
        ]
    }
}

/// Performance assertion helpers
extension XCTestCase {
    
    /// Assert operation completes within time limit
    func assertPerformance<T>(
        operation: String,
        expectedTime: TimeInterval,
        _ block: () throws -> T
    ) rethrows -> T {
        let startTime = Date()
        let result = try block()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, expectedTime, 
                         "\(operation) took \(duration)s, expected < \(expectedTime)s")
        return result
    }
    
    /// Assert async operation completes within time limit
    func assertAsyncPerformance<T>(
        operation: String,
        expectedTime: TimeInterval,
        _ block: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, expectedTime, 
                         "\(operation) took \(duration)s, expected < \(expectedTime)s")
        return result
    }
}

/// Mock data generators
struct MockDataGenerator {
    
    static func generateTransactions(count: Int) -> [[String: Any]] {
        return (1...count).map { i in
            [
                "id": UUID().uuidString,
                "amount": Double.random(in: 5.0...500.0),
                "description": "Transaction \(i)",
                "date": Date().addingTimeInterval(-Double(i * 86400)),
                "type": i % 2 == 0 ? "income" : "expense",
                "category": ["Food", "Transport", "Entertainment", "Bills", "Shopping"].randomElement()!
            ]
        }
    }
    
    static func generateHabits(count: Int) -> [[String: Any]] {
        let habitNames = ["Exercise", "Read", "Meditate", "Drink Water", "Walk", "Study", "Cook", "Sleep Early"]
        
        return (1...count).map { i in
            [
                "id": UUID().uuidString,
                "name": habitNames.randomElement() ?? "Habit \(i)",
                "description": "Description for habit \(i)",
                "frequency": ["daily", "weekly", "monthly"].randomElement()!,
                "isActive": Bool.random(),
                "streak": Int.random(in: 0...30)
            ]
        }
    }
    
    static func generateCodeFiles(count: Int) -> [[String: Any]] {
        let languages = ["swift", "javascript", "python", "java", "typescript"]
        let fileTypes = ["class", "function", "interface", "enum", "struct"]
        
        return (1...count).map { i in
            let language = languages.randomElement()!
            let fileType = fileTypes.randomElement()!
            
            return [
                "id": UUID().uuidString,
                "name": "\(fileType.capitalized)\(i).\(language)",
                "content": generateCodeContent(language: language, type: fileType, index: i),
                "language": language,
                "size": Int.random(in: 100...5000),
                "complexity": Int.random(in: 1...10)
            ]
        }
    }
    
    private static func generateCodeContent(language: String, type: String, index: Int) -> String {
        switch language {
        case "swift":
            return """
            import Foundation
            
            class \(type.capitalized)\(index) {
                private let property\(index): String
                
                init(property: String) {
                    self.property\(index) = property
                }
                
                func method\(index)() -> String {
                    return "Result from \(type) \(index): \\(property\(index))"
                }
            }
            """
        case "javascript":
            return """
            class \(type.capitalized)\(index) {
                constructor(property) {
                    this.property\(index) = property;
                }
                
                method\(index)() {
                    return `Result from \(type) \(index): ${this.property\(index)}`;
                }
            }
            
            module.exports = \(type.capitalized)\(index);
            """
        case "python":
            return """
            class \(type.capitalized)\(index):
                def __init__(self, property):
                    self.property\(index) = property
                
                def method\(index)(self):
                    return f"Result from \(type) \(index): {self.property\(index)}"
            """
        default:
            return "// \(type.capitalized)\(index) in \(language)"
        }
    }
}
