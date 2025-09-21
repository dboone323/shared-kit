import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Advanced Animation System

// Comprehensive animation framework for sophisticated UI interactions across all projects

// MARK: - Animation Timing Functions

public enum AnimationTiming {
    // Predefined easing curves
    public static let springBouncy = Animation.interpolatingSpring(
        mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0
    )
    
    public static let springSmooth = Animation.interpolatingSpring(
        mass: 1.0, stiffness: 150, damping: 15, initialVelocity: 0
    )
    
    public static let springSnappy = Animation.interpolatingSpring(
        mass: 0.7, stiffness: 200, damping: 12, initialVelocity: 0
    )
    
    public static let easeInOut = Animation.timingCurve(0.42, 0, 0.58, 1, duration: 0.3)
    public static let easeOut = Animation.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.3)
    public static let easeIn = Animation.timingCurve(0.55, 0.06, 0.68, 0.19, duration: 0.3)
    
    // Custom curve for delightful micro-interactions
    public static let delight = Animation.timingCurve(0.175, 0.885, 0.32, 1.275, duration: 0.4)
    
    // Performance-optimized curves
    public static let quick = Animation.easeOut(duration: 0.15)
    public static let standard = Animation.easeInOut(duration: 0.25)
    public static let slow = Animation.easeInOut(duration: 0.5)
}

// MARK: - Animated Values

@propertyWrapper
public struct AnimatedValue<T: VectorArithmetic>: DynamicProperty {
    @State private var value: T
    private let animation: Animation
    
    public init(wrappedValue: T, animation: Animation = AnimationTiming.standard) {
        self._value = State(initialValue: wrappedValue)
        self.animation = animation
    }
    
    public var wrappedValue: T {
        get { self.value }
        nonmutating set {
            withAnimation(animation) {
                value = newValue
            }
        }
    }
    
    public var projectedValue: Binding<T> {
        Binding(
            get: { self.value },
            set: { newValue in
                withAnimation(self.animation) {
                    self.value = newValue
                }
            }
        )
    }
}

// MARK: - Gesture Animations

public enum GestureAnimations {
    // Haptic feedback integration
    public static func hapticFeedback(style: Int = 1) {
        #if canImport(UIKit)
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = switch style {
        case 0: .light
        case 2: .heavy
        default: .medium
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: feedbackStyle)
        impactFeedback.impactOccurred()
        #endif
    }
    
    // Scale animation for touch interactions
    public static func scaleOnPress(
        scale: CGFloat = 0.95,
        animation: Animation = AnimationTiming.quick,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .scaleEffect(scale)
            .animation(animation, value: scale)
    }
    
    // Bounce animation for buttons
    public static func bounceOnTap(
        scale: CGFloat = 1.1,
        duration: Double = 0.1,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .scaleEffect(scale)
            .animation(
                Animation.easeInOut(duration: duration).repeatCount(2, autoreverses: true),
                value: scale
            )
    }
}

// MARK: - Advanced View Modifiers

public struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .foregroundColor(.clear)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: self.isAnimating ? 200 : -200)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: self.isAnimating
                    )
            )
            .clipped()
            .onAppear {
                self.isAnimating = true
            }
    }
}

public struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let scale: CGFloat
    let opacity: Double
    let duration: Double
    
    public init(scale: CGFloat = 1.1, opacity: Double = 0.6, duration: Double = 1.0) {
        self.scale = scale
        self.opacity = opacity
        self.duration = duration
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPulsing ? self.scale : 1.0)
            .opacity(self.isPulsing ? self.opacity : 1.0)
            .animation(
                Animation.easeInOut(duration: self.duration).repeatForever(autoreverses: true),
                value: self.isPulsing
            )
            .onAppear {
                self.isPulsing = true
            }
    }
}

public struct BreathingEffect: ViewModifier {
    @State private var isBreathing = false
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isBreathing ? 1.05 : 0.95)
            .opacity(self.isBreathing ? 1.0 : 0.8)
            .animation(
                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: self.isBreathing
            )
            .onAppear {
                self.isBreathing = true
            }
    }
}

// MARK: - Advanced Transitions

public struct SlideTransition: ViewModifier {
    let isPresented: Bool
    let edge: Edge
    let offset: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .offset(
                x: self.edge == .leading || self
                    .edge == .trailing ? (self.isPresented ? 0 : (self.edge == .leading ? -self.offset : self.offset)) : 0,
                y: self.edge == .top || self.edge == .bottom ? (self.isPresented ? 0 : (self.edge == .top ? -self.offset : self.offset)) : 0
            )
            .opacity(self.isPresented ? 1 : 0)
            .animation(AnimationTiming.springSmooth, value: self.isPresented)
    }
}

public struct ScaleTransition: ViewModifier {
    let isPresented: Bool
    let scale: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPresented ? 1.0 : self.scale)
            .opacity(self.isPresented ? 1.0 : 0.0)
            .animation(AnimationTiming.springBouncy, value: self.isPresented)
    }
}

public struct RotationTransition: ViewModifier {
    let isPresented: Bool
    let degrees: Double
    
    public func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(self.isPresented ? 0 : self.degrees))
            .opacity(self.isPresented ? 1.0 : 0.0)
            .animation(AnimationTiming.springSmooth, value: self.isPresented)
    }
}

// MARK: - Complex Animation Sequences

public class AnimationSequence: ObservableObject {
    @Published public var currentStep: Int = 0
    @Published public var isRunning: Bool = false
    
    private var steps: [(delay: TimeInterval, animation: () -> Void)] = []
    private var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    public func addStep(delay: TimeInterval = 0, animation: @escaping () -> Void) -> AnimationSequence {
        self.steps.append((delay: delay, animation: animation))
        return self
    }
    
    public func run() {
        guard !self.isRunning else { return }
        self.isRunning = true
        self.currentStep = 0
        
        self.runStep(0)
    }
    
    public func stop() {
        self.isRunning = false
        self.cancellables.removeAll()
    }
    
    private func runStep(_ index: Int) {
        guard index < self.steps.count, self.isRunning else {
            self.isRunning = false
            return
        }
        
        let step = self.steps[index]
        self.currentStep = index
        
        Timer.publish(every: step.delay, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { _ in
                step.animation()
                self.runStep(index + 1)
            }
            .store(in: &self.cancellables)
    }
}

// MARK: - Interactive Animations

public struct DragToRevealModifier: ViewModifier {
    @State private var dragOffset: CGSize = .zero
    @State private var isRevealed: Bool = false
    
    let threshold: CGFloat
    let onReveal: () -> Void
    
    public init(threshold: CGFloat = 100, onReveal: @escaping () -> Void) {
        self.threshold = threshold
        self.onReveal = onReveal
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(self.dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.dragOffset = value.translation
                        
                        if abs(self.dragOffset.width) > self.threshold, !self.isRevealed {
                            self.isRevealed = true
                            GestureAnimations.hapticFeedback(style: 1)
                        }
                    }
                    .onEnded { _ in
                        withAnimation(AnimationTiming.springBouncy) {
                            if abs(self.dragOffset.width) > self.threshold {
                                self.onReveal()
                            }
                            self.dragOffset = .zero
                            self.isRevealed = false
                        }
                    }
            )
    }
}

// MARK: - Loading Animations

public struct LoadingDots: View {
    @State private var animationStates: [Bool] = [false, false, false]
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .opacity(self.animationStates[index] ? 1.0 : 0.3)
                    .scaleEffect(self.animationStates[index] ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: self.animationStates[index]
                    )
            }
        }
        .onAppear {
            for i in 0 ..< self.animationStates.count {
                self.animationStates[i] = true
            }
        }
    }
}

public struct LoadingSpinner: View {
    @State private var isRotating = false
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    public init(size: CGFloat = 24, lineWidth: CGFloat = 3, color: Color = .primary) {
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
    }
    
    public var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(self.color, style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round))
            .frame(width: self.size, height: self.size)
            .rotationEffect(.degrees(self.isRotating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                value: self.isRotating
            )
            .onAppear {
                self.isRotating = true
            }
    }
}

public struct ProgressWave: View {
    @State private var waveOffset: CGFloat = 0
    let progress: Double
    let height: CGFloat
    let color: Color
    
    public init(progress: Double, height: CGFloat = 20, color: Color = .blue) {
        self.progress = progress
        self.height = height
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let progressWidth = width * CGFloat(self.progress)
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    let y = sin((relativeX * 4 * .pi) + self.waveOffset) * 5 + self.height / 2
                    
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                path.addLine(to: CGPoint(x: progressWidth, y: self.height))
                path.addLine(to: CGPoint(x: 0, y: self.height))
                path.closeSubpath()
            }
            .fill(self.color)
            .clipped()
            .animation(
                Animation.linear(duration: 2.0).repeatForever(autoreverses: false),
                value: self.waveOffset
            )
            .onAppear {
                self.waveOffset = 2 * .pi
            }
        }
        .frame(height: self.height)
    }
}

// MARK: - Particle System

public struct ParticleSystem: View {
    @State private var particles: [Particle] = []
    let particleCount: Int
    let emissionRate: TimeInterval
    let particleLifetime: TimeInterval
    let particleSize: CGFloat
    let particleColor: Color
    
    public init(
        particleCount: Int = 50,
        emissionRate: TimeInterval = 0.1,
        particleLifetime: TimeInterval = 3.0,
        particleSize: CGFloat = 4,
        particleColor: Color = .white
    ) {
        self.particleCount = particleCount
        self.emissionRate = emissionRate
        self.particleLifetime = particleLifetime
        self.particleSize = particleSize
        self.particleColor = particleColor
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(self.particles, id: \.id) { particle in
                    Circle()
                        .fill(self.particleColor)
                        .frame(width: self.particleSize, height: self.particleSize)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                }
            }
            .onAppear {
                self.startEmission(in: geometry.frame(in: .local))
            }
        }
    }
    
    private func startEmission(in bounds: CGRect) {
        Timer.scheduledTimer(withTimeInterval: self.emissionRate, repeats: true) { _ in
            if self.particles.count < self.particleCount {
                let newParticle = Particle(
                    position: CGPoint(
                        x: CGFloat.random(in: 0 ... bounds.width),
                        y: bounds.height
                    ),
                    velocity: CGPoint(
                        x: CGFloat.random(in: -50 ... 50),
                        y: CGFloat.random(in: -100 ... -50)
                    )
                )
                
                self.particles.append(newParticle)
                self.animateParticle(newParticle, in: bounds)
            }
        }
    }
    
    private func animateParticle(_ particle: Particle, in bounds: CGRect) {
        withAnimation(Animation.linear(duration: self.particleLifetime)) {
            if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                self.particles[index].position.x += particle.velocity.x * CGFloat(self.particleLifetime)
                self.particles[index].position.y += particle.velocity.y * CGFloat(self.particleLifetime)
                self.particles[index].opacity = 0
                self.particles[index].scale = 0.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.particleLifetime) {
            self.particles.removeAll { $0.id == particle.id }
        }
    }
}

private struct Particle {
    let id = UUID()
    var position: CGPoint
    let velocity: CGPoint
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
}

// MARK: - Morphing Animations

public struct MorphingShape: View {
    @State private var morphProgress: CGFloat = 0
    let shapes: [Path]
    let duration: Double
    let color: Color
    
    public init(shapes: [Path], duration: Double = 2.0, color: Color = .primary) {
        self.shapes = shapes
        self.duration = duration
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { _ in
            if !self.shapes.isEmpty {
                MorphPath(
                    shapes: self.shapes,
                    progress: self.morphProgress
                )
                .fill(self.color)
                .animation(
                    Animation.easeInOut(duration: self.duration).repeatForever(autoreverses: true),
                    value: self.morphProgress
                )
                .onAppear {
                    self.morphProgress = 1.0
                }
            }
        }
    }
}

private struct MorphPath: Shape {
    let shapes: [Path]
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        guard self.shapes.count >= 2 else { return self.shapes.first ?? Path() }
        
        let currentIndex = Int(progress * CGFloat(self.shapes.count - 1))
        let nextIndex = min(currentIndex + 1, shapes.count - 1)
        let localProgress = self.progress * CGFloat(self.shapes.count - 1) - CGFloat(currentIndex)
        
        if currentIndex == nextIndex {
            return self.shapes[currentIndex]
        }
        
        return self.interpolatePaths(
            from: self.shapes[currentIndex],
            to: self.shapes[nextIndex],
            progress: localProgress
        )
    }
    
    private func interpolatePaths(from: Path, to: Path, progress: CGFloat) -> Path {
        // Simplified path interpolation - in production, you'd use more sophisticated path interpolation
        // For demonstration, we'll just cross-fade between paths
        // Real implementation would interpolate path elements
        if progress < 0.5 {
            from
        } else {
            to
        }
    }
}

// MARK: - Advanced Progress Indicators

public struct CircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        backgroundColor: Color = Color.gray.opacity(0.3),
        foregroundColor: Color = .blue
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(self.backgroundColor, lineWidth: self.lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(self.progress))
                .stroke(
                    self.foregroundColor,
                    style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AnimationTiming.springSmooth, value: self.progress)
            
            Text("\(Int(self.progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(self.foregroundColor)
        }
    }
}

public struct AnimatedGradient: View {
    @State private var gradientOffset: CGFloat = 0
    let colors: [Color]
    let speed: Double
    
    public init(colors: [Color], speed: Double = 1.0) {
        self.colors = colors
        self.speed = speed
    }
    
    public var body: some View {
        LinearGradient(
            gradient: Gradient(colors: self.colors),
            startPoint: UnitPoint(x: self.gradientOffset, y: 0),
            endPoint: UnitPoint(x: self.gradientOffset + 1, y: 1)
        )
        .animation(
            Animation.linear(duration: 2.0 / self.speed).repeatForever(autoreverses: false),
            value: self.gradientOffset
        )
        .onAppear {
            self.gradientOffset = 1.0
        }
    }
}

// MARK: - View Extensions for Easy Animation

public extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func pulse(scale: CGFloat = 1.1, opacity: Double = 0.6, duration: Double = 1.0) -> some View {
        modifier(PulseEffect(scale: scale, opacity: opacity, duration: duration))
    }
    
    func breathing() -> some View {
        modifier(BreathingEffect())
    }
    
    func slideTransition(isPresented: Bool, from edge: Edge, offset: CGFloat = 300) -> some View {
        modifier(SlideTransition(isPresented: isPresented, edge: edge, offset: offset))
    }
    
    func scaleTransition(isPresented: Bool, scale: CGFloat = 0.5) -> some View {
        modifier(ScaleTransition(isPresented: isPresented, scale: scale))
    }
    
    func rotationTransition(isPresented: Bool, degrees: Double = 180) -> some View {
        modifier(RotationTransition(isPresented: isPresented, degrees: degrees))
    }
    
    func dragToReveal(threshold: CGFloat = 100, onReveal: @escaping () -> Void) -> some View {
        modifier(DragToRevealModifier(threshold: threshold, onReveal: onReveal))
    }
}

// MARK: - Animation Presets

public enum AnimationPresets {
    // Quick micro-interactions
    public static let buttonPress = Animation.easeInOut(duration: 0.1)
    public static let toggle = Animation.easeInOut(duration: 0.2)
    public static let hover = Animation.easeOut(duration: 0.15)
    
    // Modal and navigation transitions
    public static let modalPresent = AnimationTiming.springBouncy.delay(0.1)
    public static let modalDismiss = AnimationTiming.springSmooth
    public static let navigationPush = Animation.easeInOut(duration: 0.35)
    
    // Content changes
    public static let contentFade = Animation.easeInOut(duration: 0.3)
    public static let contentSlide = Animation.easeOut(duration: 0.4)
    public static let contentScale = AnimationTiming.springBouncy
    
    // Loading states
    public static let loadingAppear = Animation.easeOut(duration: 0.2)
    public static let loadingDisappear = Animation.easeIn(duration: 0.15)
    
    // Success/error feedback
    public static let success = AnimationTiming.springBouncy.delay(0.1)
    public static let error = Animation.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true)
}

// MARK: - Performance Optimized Animations

public struct PerformanceOptimizedView<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        self.content
            .opacity(self.isVisible ? 1 : 0)
            .onAppear {
                // Delay appearance to ensure smooth loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AnimationTiming.standard) {
                        self.isVisible = true
                    }
                }
            }
    }
}

// MARK: - Accessibility Support

public extension View {
    func accessibleAnimation(reducedMotion: Bool = false) -> some View {
        #if canImport(UIKit)
        let isReducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #else
        let isReducedMotionEnabled = reducedMotion
        #endif
        
        if isReducedMotionEnabled {
            return AnyView(self)
        } else {
            return AnyView(self)
        }
    }
}
