import Combine
import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Advanced Animation System for Quantum Workspace
/// Provides sophisticated SwiftUI animations with performance optimization
@available(iOS 15.0, macOS 12.0, *)
public struct AdvancedAnimations {
    // MARK: - Animation Timing Functions
    
    public static let smoothEaseInOut = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.6)
    public static let bounceEaseOut = Animation.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.0)
    public static let snappyEaseOut = Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.0)
    public static let gentleSpring = Animation.spring(response: 1.2, dampingFraction: 0.9, blendDuration: 0.0)
    
    // MARK: - Complex Animation Sequences
    
    @ViewBuilder
    public static func animatedEntry(
        @ViewBuilder content: @escaping () -> some View,
        delay: Double = 0,
        duration: Double = 0.6
    ) -> some View {
        content()
            .scaleEffect(0.8)
            .opacity(0)
            .onAppear {
                withAnimation(self.smoothEaseInOut.delay(delay)) {
                    // Animation will be applied by SwiftUI automatically
                }
            }
            .scaleEffect(1.0)
            .opacity(1.0)
    }
    
    @ViewBuilder
    public static func slideInFromBottom(
        @ViewBuilder content: @escaping () -> some View,
        offset: CGFloat = 100,
        delay: Double = 0
    ) -> some View {
        content()
            .offset(y: offset)
            .opacity(0)
            .onAppear {
                withAnimation(self.snappyEaseOut.delay(delay)) {
                    // Animation applied automatically
                }
            }
            .offset(y: 0)
            .opacity(1.0)
    }
    
    // MARK: - Performance Optimized Animations
    
    public struct OptimizedTransition {
        public let animation: Animation
        public let shouldAnimate: Bool
        
        public init(animation: Animation = .default, shouldAnimate: Bool = true) {
            self.animation = animation
            self.shouldAnimate = shouldAnimate
        }
    }
    
    // MARK: - Custom Animation Modifiers
    
    public struct FadeSlideModifier: ViewModifier {
        let isVisible: Bool
        let direction: SlideDirection
        let distance: CGFloat
        
        public enum SlideDirection {
            case up, down, left, right
        }
        
        public func body(content: Content) -> some View {
            content
                .opacity(self.isVisible ? 1 : 0)
                .offset(
                    x: self.isVisible ? 0 : (self.direction == .left ? -self.distance : self.direction == .right ? self.distance : 0),
                    y: self.isVisible ? 0 : (self.direction == .up ? -self.distance : self.direction == .down ? self.distance : 0)
                )
                .animation(smoothEaseInOut, value: self.isVisible)
        }
    }
    
    // MARK: - Shake Animation
    
    public struct ShakeEffect: ViewModifier {
        let shakeNumber: Int
        
        public func body(content: Content) -> some View {
            content
                .offset(x: self.shakeNumber != 0 ? (self.shakeNumber % 2 == 0 ? -5 : 5) : 0)
        }
    }
    
    // MARK: - Pulse Animation
    
    public struct PulseEffect: ViewModifier {
        @State private var isAnimating = false
        let minScale: CGFloat
        let maxScale: CGFloat
        let duration: Double
        
        public init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) {
            self.minScale = minScale
            self.maxScale = maxScale
            self.duration = duration
        }
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(self.isAnimating ? self.maxScale : self.minScale)
                .animation(Animation.easeInOut(duration: self.duration).repeatForever(autoreverses: true), value: self.isAnimating)
                .onAppear {
                    self.isAnimating = true
                }
        }
    }
    
    // MARK: - Loading Spinner
    
    public struct LoadingSpinner: View {
        @State private var isRotating = false
        let size: CGFloat
        let lineWidth: CGFloat
        let color: Color
        
        public init(size: CGFloat = 40, lineWidth: CGFloat = 4, color: Color = .blue) {
            self.size = size
            self.lineWidth = lineWidth
            self.color = color
        }
        
        public var body: some View {
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(self.color, style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round))
                .frame(width: self.size, height: self.size)
                .rotationEffect(.degrees(self.isRotating ? 360 : 0))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: self.isRotating)
                .onAppear {
                    self.isRotating = true
                }
        }
    }
    
    // MARK: - Morphing Shape
    
    public struct MorphingShape: View {
        @State private var morph = false
        let fromShape: AnyShape
        let toShape: AnyShape
        let color: Color
        let duration: Double
        
        public init(
            from: some Shape,
            to: some Shape,
            color: Color = .blue,
            duration: Double = 2.0
        ) {
            self.fromShape = AnyShape(from)
            self.toShape = AnyShape(to)
            self.color = color
            self.duration = duration
        }
        
        public var body: some View {
            ZStack {
                if self.morph {
                    self.toShape
                        .fill(self.color)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    self.fromShape
                        .fill(self.color)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: self.duration).repeatForever(autoreverses: true)) {
                    self.morph.toggle()
                }
            }
        }
    }
    
    // MARK: - Particle System
    
    public struct ParticleEffect: View {
        @State private var particles: [Particle] = []
        let particleCount: Int
        let colors: [Color]
        
        public init(particleCount: Int = 20, colors: [Color] = [.blue, .purple, .pink]) {
            self.particleCount = particleCount
            self.colors = colors
        }
        
        public var body: some View {
            ZStack {
                ForEach(self.particles, id: \.id) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                self.generateParticles()
                self.animateParticles()
            }
        }
        
        private func generateParticles() {
            self.particles = (0 ..< self.particleCount).map { _ in
                Particle(
                    id: UUID(),
                    position: CGPoint(x: 200, y: 200),
                    velocity: CGPoint(
                        x: Double.random(in: -50 ... 50),
                        y: Double.random(in: -50 ... 50)
                    ),
                    size: Double.random(in: 4 ... 12),
                    color: self.colors.randomElement() ?? .blue,
                    opacity: Double.random(in: 0.5 ... 1.0)
                )
            }
        }
        
        private func animateParticles() {
            Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                self.updateParticles()
            }
        }
        
        private func updateParticles() {
            for index in self.particles.indices {
                self.particles[index].position.x += self.particles[index].velocity.x * 0.016
                self.particles[index].position.y += self.particles[index].velocity.y * 0.016
                self.particles[index].opacity -= 0.01
                
                if self.particles[index].opacity <= 0 {
                    self.particles[index] = Particle(
                        id: UUID(),
                        position: CGPoint(x: 200, y: 200),
                        velocity: CGPoint(
                            x: Double.random(in: -50 ... 50),
                            y: Double.random(in: -50 ... 50)
                        ),
                        size: Double.random(in: 4 ... 12),
                        color: self.colors.randomElement() ?? .blue,
                        opacity: Double.random(in: 0.5 ... 1.0)
                    )
                }
            }
        }
        
        private struct Particle {
            let id: UUID
            var position: CGPoint
            let velocity: CGPoint
            let size: Double
            let color: Color
            var opacity: Double
        }
    }
}

// MARK: - View Extensions

public extension View {
    func fadeSlide(
        isVisible: Bool,
        direction: AdvancedAnimations.FadeSlideModifier.SlideDirection = .up,
        distance: CGFloat = 20
    ) -> some View {
        modifier(AdvancedAnimations.FadeSlideModifier(
            isVisible: isVisible,
            direction: direction,
            distance: distance
        ))
    }
    
    func shake(with number: Int) -> some View {
        modifier(AdvancedAnimations.ShakeEffect(shakeNumber: number))
    }
    
    func pulse(
        minScale: CGFloat = 0.95,
        maxScale: CGFloat = 1.05,
        duration: Double = 1.0
    ) -> some View {
        modifier(AdvancedAnimations.PulseEffect(
            minScale: minScale,
            maxScale: maxScale,
            duration: duration
        ))
    }
}

// MARK: - AnyShape Helper

public struct AnyShape: Shape {
    private let _path: (CGRect) -> Path
    
    public init(_ shape: some Shape) {
        self._path = { rect in
            shape.path(in: rect)
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        self._path(rect)
    }
}
