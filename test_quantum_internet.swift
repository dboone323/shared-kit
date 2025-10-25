#!/usr/bin/env swift

import Foundation

// Test script for Quantum Internet implementation
print("🧪 Testing Quantum Internet Implementation")
print("==========================================")

// Create quantum internet instance
let quantumInternet = QuantumInternet()

// Run initialization
Task {
    await quantumInternet.initializeQuantumInternet()

    // Run demonstration
    await quantumInternet.demonstrateQuantumInternet()

    print("\n✅ Quantum Internet test completed successfully!")
}

// Keep the script running for async operations
RunLoop.main.run()
