import Foundation

public enum SupportedPlatform: String, CaseIterable, Sendable {
    case iOS
    case macOS
    case watchOS
    case visionOS
}

public struct PlatformFeatureFlags: Sendable, Codable, Equatable {
    public var widgetsEnabled: Bool
    public var siriShortcutsEnabled: Bool
    public var coreMLEnabled: Bool
    public var arkitEnabled: Bool
    public var cloudKitSharingEnabled: Bool
    public var healthKitEnabled: Bool
    public var homeKitEnabled: Bool
    public var callKitEnabled: Bool
    public var carPlayEnabled: Bool

    public init(
        widgetsEnabled: Bool = false,
        siriShortcutsEnabled: Bool = false,
        coreMLEnabled: Bool = false,
        arkitEnabled: Bool = false,
        cloudKitSharingEnabled: Bool = false,
        healthKitEnabled: Bool = false,
        homeKitEnabled: Bool = false,
        callKitEnabled: Bool = false,
        carPlayEnabled: Bool = false
    ) {
        self.widgetsEnabled = widgetsEnabled
        self.siriShortcutsEnabled = siriShortcutsEnabled
        self.coreMLEnabled = coreMLEnabled
        self.arkitEnabled = arkitEnabled
        self.cloudKitSharingEnabled = cloudKitSharingEnabled
        self.healthKitEnabled = healthKitEnabled
        self.homeKitEnabled = homeKitEnabled
        self.callKitEnabled = callKitEnabled
        self.carPlayEnabled = carPlayEnabled
    }
}

public actor PlatformFeatureRegistry {
    public static let shared = PlatformFeatureRegistry()

    private var registry: [SupportedPlatform: PlatformFeatureFlags] = [:]

    public init() {}

    public func setFlags(_ flags: PlatformFeatureFlags, for platform: SupportedPlatform) {
        registry[platform] = flags
    }

    public func flags(for platform: SupportedPlatform) -> PlatformFeatureFlags {
        registry[platform] ?? PlatformFeatureFlags()
    }

    public func reset() {
        registry.removeAll()
    }
}
