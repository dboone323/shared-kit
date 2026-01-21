@testable import SharedKit
import XCTest

@available(macOS 12.0, *)
final class CircuitBreakerTests: XCTestCase {
    func testCircuitBreakerInitiallyClosed() async {
        let breaker = CircuitBreaker()
        let state = await breaker.getCurrentState()
        XCTAssertEqual(state, .closed)
    }
    
    func testSuccessRemainsClosed() async throws {
        let breaker = CircuitBreaker()
        
        let result = try await breaker.execute {
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        let state = await breaker.getCurrentState()
        XCTAssertEqual(state, .closed)
    }
    
    func testFailuresOpenCircuit() async {
        let breaker = CircuitBreaker(failureThreshold: 2)
        
        // 1st failure
        try? await breaker.execute { throw NSError(domain: "test", code: 1) }
        var state = await breaker.getCurrentState()
        XCTAssertEqual(state, .closed)
        
        // 2nd failure - should trip
        try? await breaker.execute { throw NSError(domain: "test", code: 1) }
        state = await breaker.getCurrentState()
        XCTAssertEqual(state, .open)
    }
    
    func testOpenCircuitRejectsCalls() async {
        let breaker = CircuitBreaker(failureThreshold: 1)
        
        // Trip it
        try? await breaker.execute { throw NSError(domain: "test", code: 1) }
        
        // Next call should fail fast
        do {
            _ = try await breaker.execute { "should not run" }
            XCTFail("Should have thrown circuitOpen")
        } catch let error as CircuitBreakerError {
            XCTAssertEqual(error, .circuitOpen)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testHalfOpenRecovery() async throws {
        let breaker = CircuitBreaker(
            failureThreshold: 1,
            timeout: 0.1, // fast timeout for test
            halfOpenSuccessThreshold: 2
        )
        
        // Trip
        try? await breaker.execute { throw NSError(domain: "test", code: 1) }
        
        // Wait for timeout
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        // First call should transition to half-open
        // We'll make it succeed
        _ = try await breaker.execute { "success 1" }
        
        // State should be half-open now (or closed if threshold was 1, but it is 2)
        var state = await breaker.getCurrentState()
        XCTAssertEqual(state, .halfOpen)
        
        // Second success
        _ = try await breaker.execute { "success 2" }
        
        // Should be closed now
        state = await breaker.getCurrentState()
        XCTAssertEqual(state, .closed)
    }
    
    func testHalfOpenFailureReopens() async throws {
        let breaker = CircuitBreaker(
            failureThreshold: 1,
            timeout: 0.1
        )
        
        // Trip
        try? await breaker.execute { throw NSError(domain: "test", code: 1) }
        
        // Wait
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Fail during half-open
        try? await breaker.execute { throw NSError(domain: "test", code: 1) }
        
        let state = await breaker.getCurrentState()
        XCTAssertEqual(state, .open)
    }
}
