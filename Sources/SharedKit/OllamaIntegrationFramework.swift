import Foundation

/// Backwards compatibility shim that forwards legacy `OllamaIntegrationFramework` usages
/// to the consolidated `OllamaIntegrationManager` implementation.
@available(*, deprecated, renamed: "OllamaIntegrationManager")
public typealias OllamaIntegrationFramework = OllamaIntegrationManager

/// Namespace helpers for quickly accessing and configuring a shared integration manager.
public enum OllamaIntegration {
    /// Shared manager instance used by simplified helper methods.
    @MainActor public private(set) static var shared = OllamaIntegrationManager()

    /// Replace the shared manager with a custom configuration.
    @MainActor
    public static func configureShared(config: OllamaConfig) {
        self.shared = OllamaIntegrationManager(config: config)
    }

    /// Perform a quick service health check using the shared manager.
    @MainActor
    public static func healthCheck() async -> ServiceHealth {
        await self.shared.getHealthStatus()
    }
}
