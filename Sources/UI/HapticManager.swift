// Import SharedKit for SecureLogger
@_implementationOnly import Foundation
import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif
#if canImport(CoreHaptics)
    import CoreHaptics
#endif

/// Haptic feedback manager for game interactions
/// Provides impact, notification, and custom haptic patterns
@MainActor
public final class HapticManager {
    public static let shared = HapticManager()

    #if canImport(CoreHaptics)
        private var engine: CHHapticEngine?
    #endif

    private var isHapticsEnabled = true

    private init() {
        setupHapticEngine()
    }

    // MARK: - Setup

    private func setupHapticEngine() {
        #if canImport(CoreHaptics)
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

            do {
                engine = try CHHapticEngine()
                try engine?.start()

                engine?.resetHandler = { [weak self] in
                    do {
                        try self?.engine?.start()
                    } catch {
                        SecureLogger.error(
                            "Failed to restart haptic engine", category: .haptics, error: error)
                    }
                }
            } catch {
                SecureLogger.error(
                    "Failed to create haptic engine", category: .haptics, error: error)
            }
        #endif
    }

    // MARK: - Public API

    /// Toggle haptics on/off
    public func setEnabled(_ enabled: Bool) {
        isHapticsEnabled = enabled
    }

    /// Light impact for UI interactions
    public func lightImpact() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        #endif
    }

    /// Medium impact for game events
    public func mediumImpact() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        #endif
    }

    /// Heavy impact for collisions
    public func heavyImpact() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        #endif
    }

    /// Rigid impact for solid hits
    public func rigidImpact() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        #endif
    }

    /// Soft impact for near-misses
    public func softImpact() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        #endif
    }

    /// Success notification
    public func success() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        #endif
    }

    /// Warning notification
    public func warning() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        #endif
    }

    /// Error notification for game over
    public func error() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        #endif
    }

    /// Selection tick for UI navigation
    public func selection() {
        guard isHapticsEnabled else { return }
        #if canImport(UIKit) && !os(tvOS)
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        #endif
    }

    // MARK: - Game-Specific Haptics

    /// Collision with obstacle
    public func collision() {
        heavyImpact()
    }

    /// Near miss - close call with obstacle
    public func nearMiss() {
        softImpact()
    }

    /// Power-up collected
    public func powerUp() {
        success()
    }

    /// Score milestone reached
    public func milestone() {
        Task {
            mediumImpact()
            try? await Task.sleep(nanoseconds: 100_000_000)
            mediumImpact()
        }
    }

    /// Game over
    public func gameOver() {
        error()
    }

    /// New high score
    public func newHighScore() {
        Task {
            success()
            try? await Task.sleep(nanoseconds: 150_000_000)
            success()
            try? await Task.sleep(nanoseconds: 150_000_000)
            success()
        }
    }

    // MARK: - Custom Haptic Patterns

    #if canImport(CoreHaptics)
        /// Play a custom intensity haptic
        public func customImpact(intensity: Float, sharpness: Float) {
            guard isHapticsEnabled, let engine = engine else { return }

            let hapticEvent = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: 0
            )

            do {
                let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                SecureLogger.error("Failed to play custom haptic", category: .haptics, error: error)
            }
        }

        /// Rumble effect for continuous feedback
        public func rumble(duration: TimeInterval, intensity: Float = 0.5) {
            guard isHapticsEnabled, let engine = engine else { return }

            let hapticEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                ],
                relativeTime: 0,
                duration: duration
            )

            do {
                let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                SecureLogger.error("Failed to play rumble", category: .haptics, error: error)
            }
        }
    #endif
}

// MARK: - SwiftUI View Modifier

public struct HapticModifier: ViewModifier {
    let type: HapticType

    public enum HapticType {
        case light, medium, heavy, success, warning, error, selection
    }

    public func body(content: Content) -> some View {
        content.onTapGesture {
            Task { @MainActor in
                switch type {
                case .light: HapticManager.shared.lightImpact()
                case .medium: HapticManager.shared.mediumImpact()
                case .heavy: HapticManager.shared.heavyImpact()
                case .success: HapticManager.shared.success()
                case .warning: HapticManager.shared.warning()
                case .error: HapticManager.shared.error()
                case .selection: HapticManager.shared.selection()
                }
            }
        }
    }
}

extension View {
    /// Add haptic feedback on tap
    public func hapticFeedback(_ type: HapticModifier.HapticType) -> some View {
        modifier(HapticModifier(type: type))
    }
}
