//
//  SelfHealingEngineIntegrationTests.swift
//  Quantum-workspace
//
//  Created by Phase 6 Implementation
//  Integration tests for Self-Healing Architecture (Task 45)
//

import Combine
import XCTest

@testable import Shared

final class SelfHealingEngineIntegrationTests: XCTestCase {

    var healingEngine: SelfHealingEngine!
    var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        healingEngine = SelfHealingEngine.shared
        cancellables = Set<AnyCancellable>()

        // Stop any existing engine
        await healingEngine.stop()

        // Reset state
        await healingEngine.start()
    }

    override func tearDown() async throws {
        await healingEngine.stop()
        cancellables = nil
    }

    // MARK: - Basic Functionality Tests

    func testEngineStartsAndStops() async throws {
        // Given
        XCTAssertFalse(healingEngine.isActive)

        // When
        await healingEngine.start()

        // Then
        XCTAssertTrue(healingEngine.isActive)
        XCTAssertEqual(healingEngine.systemHealth, .healthy)

        // When
        await healingEngine.stop()

        // Then
        XCTAssertFalse(healingEngine.isActive)
    }

    func testErrorReporting() async throws {
        // Given
        await healingEngine.start()
        let error = SystemError.custom(description: "Test error", metadata: ["test": "true"])

        // When
        await healingEngine.reportError(error)

        // Then
        // Error should be queued for processing
        let history = healingEngine.getHealingHistory()
        XCTAssertFalse(history.isEmpty)

        // Wait for healing to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        let updatedHistory = healingEngine.getHealingHistory()
        XCTAssertGreaterThan(updatedHistory.count, history.count)
    }

    func testHealthMonitoring() async throws {
        // Given
        await healingEngine.start()

        // When - wait for monitoring cycle
        try await Task.sleep(nanoseconds: 35_000_000_000) // 35 seconds (longer than monitoring interval)

        // Then
        let healthStatus = healingEngine.getHealthStatus()
        XCTAssertFalse(healthStatus.isEmpty)

        // Should have monitored basic components
        XCTAssertNotNil(healthStatus["memory"])
        XCTAssertNotNil(healthStatus["cpu"])
        XCTAssertNotNil(healthStatus["disk"])
    }

    // MARK: - Recovery Strategy Tests

    func testMemoryLeakRecovery() async throws {
        // Given
        await healingEngine.start()
        let memoryError = SystemError.memoryLeak(detectedAt: Date(), severity: 0.9)

        // When
        await healingEngine.reportError(memoryError)

        // Then
        try await Task.sleep(nanoseconds: 3_000_000_000) // Wait for healing

        let history = healingEngine.getHealingHistory()
        let memoryHealings = history.filter { action in
            if case .memoryLeak = action.error {
                return action.strategy == .restart
            }
            return false
        }
        XCTAssertFalse(memoryHealings.isEmpty)
    }

    func testConnectivityFailureRecovery() async throws {
        // Given
        await healingEngine.start()
        let networkError = SystemError.connectivityFailure(
            endpoint: "api.example.com", error: "Connection timeout"
        )

        // When
        await healingEngine.reportError(networkError)

        // Then
        try await Task.sleep(nanoseconds: 6_000_000_000) // Wait for healing

        let history = healingEngine.getHealingHistory()
        let networkHealings = history.filter { action in
            if case .connectivityFailure = action.error {
                return action.strategy == .failover
            }
            return false
        }
        XCTAssertFalse(networkHealings.isEmpty)
    }

    func testConfigurationErrorRecovery() async throws {
        // Given
        await healingEngine.start()
        let configError = SystemError.configurationError(
            key: "database.url", expected: "localhost", actual: "invalid"
        )

        // When
        await healingEngine.reportError(configError)

        // Then
        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait for healing

        let history = healingEngine.getHealingHistory()
        let configHealings = history.filter { action in
            if case .configurationError = action.error {
                return action.strategy == .reconfigure
            }
            return false
        }
        XCTAssertFalse(configHealings.isEmpty)
    }

    // MARK: - Component Health Tests

    func testMemoryHealthCheck() async throws {
        // Given
        await healingEngine.start()

        // When - trigger health check
        try await Task.sleep(nanoseconds: 35_000_000_000) // Wait for monitoring

        // Then
        let healthStatus = healingEngine.getHealthStatus()
        let memoryHealth = healthStatus["memory"]
        XCTAssertNotNil(memoryHealth)

        // Memory health should be one of the valid states
        XCTAssertTrue(
            [ComponentHealth.healthy, .degraded, .critical, .failed].contains(memoryHealth))
    }

    func testDiskHealthCheck() async throws {
        // Given
        await healingEngine.start()

        // When - trigger health check
        try await Task.sleep(nanoseconds: 35_000_000_000) // Wait for monitoring

        // Then
        let healthStatus = healingEngine.getHealthStatus()
        let diskHealth = healthStatus["disk"]
        XCTAssertNotNil(diskHealth)

        // Disk health should be one of the valid states
        XCTAssertTrue(
            [ComponentHealth.healthy, .degraded, .critical, .failed].contains(diskHealth))
    }

    // MARK: - Concurrent Recovery Tests

    func testConcurrentRecoveries() async throws {
        // Given
        await healingEngine.start()

        // When - report multiple errors simultaneously
        let errors = [
            SystemError.memoryLeak(detectedAt: Date(), severity: 0.8),
            SystemError.connectivityFailure(endpoint: "api1", error: "timeout"),
            SystemError.configurationError(key: "config1", expected: "value1", actual: "value2"),
            SystemError.resourceExhaustion(resource: "cpu", usage: 0.95),
        ]

        for error in errors {
            await healingEngine.reportError(error)
        }

        // Then - wait for processing
        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds

        let history = healingEngine.getHealingHistory()
        XCTAssertGreaterThanOrEqual(history.count, errors.count)

        // Check that recoveries were attempted
        let successfulRecoveries = history.filter(\.success)
        XCTAssertGreaterThan(successfulRecoveries.count, 0)
    }

    // MARK: - Manual Healing Tests

    func testManualComponentHealing() async throws {
        // Given
        await healingEngine.start()

        // When
        await healingEngine.healComponent("memory")

        // Then
        try await Task.sleep(nanoseconds: 3_000_000_000) // Wait for healing

        let history = healingEngine.getHealingHistory()
        let manualHealings = history.filter { action in
            if case let .custom(description, _) = action.error {
                return description.contains("Manual healing requested")
            }
            return false
        }
        XCTAssertFalse(manualHealings.isEmpty)
    }

    // MARK: - Data Export/Import Tests

    func testHealingHistoryExport() async throws {
        // Given
        await healingEngine.start()
        await healingEngine.reportError(
            SystemError.custom(description: "Test export", metadata: [:]))

        try await Task.sleep(nanoseconds: 2_000_000_000) // Wait for processing

        // When
        let exportedData = healingEngine.exportHealingHistory()

        // Then
        XCTAssertNotNil(exportedData)
        XCTAssertGreaterThan(exportedData!.count, 0)
    }

    func testHealingHistoryImport() async throws {
        // Given
        let testHistory = [
            HealingAction(
                error: .custom(description: "Imported error", metadata: [:]),
                strategy: .restart,
                success: true,
                duration: 1.5,
                metadata: ["imported": "true"]
            ),
        ]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(testHistory)

        // When
        healingEngine.importHealingHistory(data)

        // Then
        let importedHistory = healingEngine.getHealingHistory()
        XCTAssertEqual(importedHistory.count, testHistory.count)
        XCTAssertEqual(importedHistory.first?.error.custom?.description, "Imported error")
    }

    // MARK: - System Health Aggregation Tests

    func testSystemHealthAggregation() async throws {
        // Given
        await healingEngine.start()

        // When - simulate various component health states
        // This would normally be done through actual monitoring, but for testing
        // we'll use the published properties

        // Then - system health should reflect the worst component health
        let healthStatus = healingEngine.getHealthStatus()

        // If any component is failed, system should be failed
        if healthStatus.values.contains(.failed) {
            XCTAssertEqual(healingEngine.systemHealth, .failed)
        }
        // If any component is critical but none failed, system should be critical
        else if healthStatus.values.contains(.critical) {
            XCTAssertEqual(healingEngine.systemHealth, .critical)
        }
        // If any component is degraded but none critical/failed, system should be degraded
        else if healthStatus.values.contains(.degraded) {
            XCTAssertEqual(healingEngine.systemHealth, .degraded)
        }
        // If all components are healthy, system should be healthy
        else {
            XCTAssertEqual(healingEngine.systemHealth, .healthy)
        }
    }

    // MARK: - Performance Tests

    func testHealingPerformance() async throws {
        // Given
        await healingEngine.start()
        let startTime = Date()

        // When - perform multiple healing operations
        for i in 0 ..< 5 {
            let error = SystemError.custom(description: "Performance test \(i)", metadata: [:])
            await healingEngine.reportError(error)
        }

        try await Task.sleep(nanoseconds: 15_000_000_000) // Wait for all healing to complete

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)

        // Then - should complete within reasonable time (allowing for async processing)
        XCTAssertLessThan(totalTime, 30.0) // Less than 30 seconds for 5 healings

        let history = healingEngine.getHealingHistory()
        XCTAssertGreaterThanOrEqual(history.count, 5)
    }

    // MARK: - Error Severity Tests

    func testErrorSeverityClassification() async throws {
        // Test memory leak severity
        let lowSeverityLeak = SystemError.memoryLeak(detectedAt: Date(), severity: 0.5)
        let highSeverityLeak = SystemError.memoryLeak(detectedAt: Date(), severity: 0.9)

        // Low severity should be degraded, high should be critical
        // Note: This tests the internal logic, but since getErrorSeverity is private,
        // we test through the behavior of the healing engine

        await healingEngine.start()

        // Report low severity - should still trigger healing but not immediately
        await healingEngine.reportError(lowSeverityLeak)

        // Report high severity - should trigger immediate healing
        await healingEngine.reportError(highSeverityLeak)

        try await Task.sleep(nanoseconds: 5_000_000_000) // Wait for processing

        let history = healingEngine.getHealingHistory()
        let highSeverityHealings = history.filter { action in
            if case let .memoryLeak(_, severity) = action.error {
                return severity > 0.8
            }
            return false
        }
        XCTAssertFalse(highSeverityHealings.isEmpty)
    }
}
