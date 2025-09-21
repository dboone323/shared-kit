import Foundation
import SwiftUI

/// Custom Transition Effects for Advanced UI Navigation
/// Provides sophisticated transition animations between views
@available(iOS 15.0, macOS 12.0, *)
public struct CustomTransitions {
    // MARK: - Slide Transitions
    
    public static let slideInFromTrailing = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    public static let slideInFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
    
    public static let slideUp = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    // MARK: - Scale Transitions
    
    public static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)
    
    public static let scaleFromCenter = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
    
    // MARK: - Rotation Transitions
    
    public static let rotateAndScale = AnyTransition.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
    )
    
    // MARK: - Custom Flip Transition
    
    public struct FlipTransition: Transition {
        let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
        
        public init(axis: (x: CGFloat, y: CGFloat, z: CGFloat) = (0, 1, 0)) {
            self.axis = axis
        }
        
        public func body(content: Content, phase: TransitionPhase) -> some View {
            content
                .rotation3DEffect(
                    .degrees(phase.isIdentity ? 0 : 90),
                    axis: self.axis
                )
                .opacity(phase.isIdentity ? 1 : 0)
        }
    }
    
    // MARK: - Iris Transition
    
    public struct IrisTransition: Transition {
        public init() {}
        
        public func body(content: Content, phase: TransitionPhase) -> some View {
            content
                .clipShape(
                    Circle()
                        .scale(phase.isIdentity ? 1 : 0)
                )
                .animation(.easeInOut(duration: 0.6), value: phase.isIdentity)
        }
    }
    
    // MARK: - Wave Transition
    
    public struct WaveTransition: Transition {
        public init() {}
        
        public func body(content: Content, phase: TransitionPhase) -> some View {
            content
                .mask(
                    Rectangle()
                        .offset(y: phase.isIdentity ? 0 : -1000)
                        .animation(.easeInOut(duration: 0.8), value: phase.isIdentity)
                )
        }
    }
}
