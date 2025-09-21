import SwiftUI

// MARK: - Custom Transition System

// Advanced transitions for sophisticated view changes across all projects

// MARK: - Custom Transition Types

public enum TransitionType {
    case slide(edge: Edge, distance: CGFloat = 300)
    case scale(from: CGFloat = 0.5, to: CGFloat = 1.0)
    case rotate(degrees: Double = 180)
    case flip(axis: FlipAxis = .horizontal)
    case morph
    case particle
    case liquid
    case elastic
    case bounce
    case zoom
    case fan
    case iris
    case ripple
}

public enum FlipAxis {
    case horizontal, vertical
}

// MARK: - Advanced Custom Transitions

public struct SlideTransitionAdvanced: ViewModifier {
    let isPresented: Bool
    let edge: Edge
    let distance: CGFloat
    let overshoot: CGFloat
    
    public init(isPresented: Bool, edge: Edge, distance: CGFloat = 300, overshoot: CGFloat = 50) {
        self.isPresented = isPresented
        self.edge = edge
        self.distance = distance
        self.overshoot = overshoot
    }
    
    public func body(content: Content) -> some View {
        let offset: CGSize = {
            let baseOffset: CGFloat = self.isPresented ? 0 : self.distance
            let overshootOffset: CGFloat = self.isPresented ? -self.overshoot : 0
            let finalOffset = baseOffset + overshootOffset
            
            switch self.edge {
            case .leading: return CGSize(width: -finalOffset, height: 0)
            case .trailing: return CGSize(width: finalOffset, height: 0)
            case .top: return CGSize(width: 0, height: -finalOffset)
            case .bottom: return CGSize(width: 0, height: finalOffset)
            }
        }()
        
        content
            .offset(offset)
            .opacity(self.isPresented ? 1 : 0)
    }
}

public struct ScaleTransitionAdvanced: ViewModifier {
    let isPresented: Bool
    let fromScale: CGFloat
    let toScale: CGFloat
    let anchor: UnitPoint
    
    public init(isPresented: Bool, fromScale: CGFloat = 0.5, toScale: CGFloat = 1.0, anchor: UnitPoint = .center) {
        self.isPresented = isPresented
        self.fromScale = fromScale
        self.toScale = toScale
        self.anchor = anchor
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPresented ? self.toScale : self.fromScale, anchor: self.anchor)
            .opacity(self.isPresented ? 1 : 0)
    }
}

public struct RotationTransitionAdvanced: ViewModifier {
    let isPresented: Bool
    let degrees: Double
    let anchor: UnitPoint
    
    public init(isPresented: Bool, degrees: Double = 180, anchor: UnitPoint = .center) {
        self.isPresented = isPresented
        self.degrees = degrees
        self.anchor = anchor
    }
    
    public func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(self.isPresented ? 0 : self.degrees), anchor: self.anchor)
            .opacity(self.isPresented ? 1 : 0)
    }
}

public struct FlipTransition: ViewModifier {
    let isPresented: Bool
    let axis: FlipAxis
    
    public init(isPresented: Bool, axis: FlipAxis = .horizontal) {
        self.isPresented = isPresented
        self.axis = axis
    }
    
    public func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(self.isPresented ? 0 : (self.axis == .horizontal ? 180 : 180)),
                axis: self.axis == .horizontal ? (x: 0, y: 1, z: 0) : (x: 1, y: 0, z: 0)
            )
            .opacity(self.isPresented ? 1 : 0)
    }
}

public struct ElasticTransition: ViewModifier {
    let isPresented: Bool
    
    public init(isPresented: Bool) {
        self.isPresented = isPresented
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPresented ? 1.0 : 0.1)
            .opacity(self.isPresented ? 1.0 : 0.0)
            .animation(
                self.isPresented
                    ? Animation.interpolatingSpring(mass: 1, stiffness: 50, damping: 5, initialVelocity: 10)
                    : Animation.easeInOut(duration: 0.2),
                value: self.isPresented
            )
    }
}

public struct BounceTransition: ViewModifier {
    let isPresented: Bool
    
    public init(isPresented: Bool) {
        self.isPresented = isPresented
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.isPresented ? 1.0 : 0.0)
            .opacity(self.isPresented ? 1.0 : 0.0)
            .animation(
                self.isPresented
                    ? Animation.interpolatingSpring(mass: 0.5, stiffness: 300, damping: 15, initialVelocity: 20)
                    : Animation.easeIn(duration: 0.15),
                value: self.isPresented
            )
    }
}

// MARK: - Geometric Transitions

public struct IrisTransition: ViewModifier {
    let isPresented: Bool
    let center: UnitPoint
    
    @State private var animationProgress: CGFloat = 0
    
    public init(isPresented: Bool, center: UnitPoint = .center) {
        self.isPresented = isPresented
        self.center = center
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                IrisShape(progress: self.animationProgress, center: self.center)
            )
            .onAppear {
                withAnimation(AnimationTiming.easeOut) {
                    self.animationProgress = self.isPresented ? 1.0 : 0.0
                }
            }
            .onChange(of: self.isPresented) { newValue in
                withAnimation(AnimationTiming.easeOut) {
                    self.animationProgress = newValue ? 1.0 : 0.0
                }
            }
    }
}

private struct IrisShape: Shape {
    var progress: CGFloat
    let center: UnitPoint
    
    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let centerPoint = CGPoint(
            x: rect.width * self.center.x,
            y: rect.height * self.center.y
        )
        
        let maxRadius = max(
            max(centerPoint.x, rect.width - centerPoint.x),
            max(centerPoint.y, rect.height - centerPoint.y)
        )
        
        let radius = maxRadius * self.progress
        
        var path = Path()
        path.addEllipse(in: CGRect(
            x: centerPoint.x - radius,
            y: centerPoint.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        return path
    }
}

public struct FanTransition: ViewModifier {
    let isPresented: Bool
    let segments: Int
    
    @State private var animationProgress: CGFloat = 0
    
    public init(isPresented: Bool, segments: Int = 8) {
        self.isPresented = isPresented
        self.segments = segments
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                FanShape(progress: self.animationProgress, segments: self.segments)
            )
            .onAppear {
                withAnimation(AnimationTiming.easeOut.delay(0.1)) {
                    self.animationProgress = self.isPresented ? 1.0 : 0.0
                }
            }
            .onChange(of: self.isPresented) { newValue in
                withAnimation(AnimationTiming.easeOut) {
                    self.animationProgress = newValue ? 1.0 : 0.0
                }
            }
    }
}

private struct FanShape: Shape {
    var progress: CGFloat
    let segments: Int
    
    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height)
        let anglePerSegment = 2 * CGFloat.pi / CGFloat(self.segments)
        let visibleSegments = Int(progress * CGFloat(self.segments))
        
        for i in 0 ..< visibleSegments {
            let startAngle = CGFloat(i) * anglePerSegment - CGFloat.pi / 2
            let endAngle = startAngle + anglePerSegment
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(radians: Double(startAngle)),
                endAngle: Angle(radians: Double(endAngle)),
                clockwise: false
            )
        }
        
        return path
    }
}

// MARK: - Liquid Transition

public struct LiquidTransition: ViewModifier {
    let isPresented: Bool
    
    @State private var waveOffset: CGFloat = 0
    @State private var animationProgress: CGFloat = 0
    
    public init(isPresented: Bool) {
        self.isPresented = isPresented
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                LiquidShape(progress: self.animationProgress, waveOffset: self.waveOffset)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    self.waveOffset = 2 * CGFloat.pi
                }
                
                withAnimation(AnimationTiming.easeInOut) {
                    self.animationProgress = self.isPresented ? 1.0 : 0.0
                }
            }
            .onChange(of: self.isPresented) { newValue in
                withAnimation(AnimationTiming.easeInOut) {
                    self.animationProgress = newValue ? 1.0 : 0.0
                }
            }
    }
}

private struct LiquidShape: Shape {
    var progress: CGFloat
    var waveOffset: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatableData(self.progress, self.waveOffset) }
        set {
            self.progress = newValue.first
            self.waveOffset = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight: CGFloat = 20
        let frequency: CGFloat = 4
        let fillHeight = rect.height * self.progress
        
        if self.progress <= 0 {
            return path
        }
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / rect.width
            let waveY = sin((relativeX * frequency * CGFloat.pi * 2) + self.waveOffset) * waveHeight * (1 - self.progress)
            let y = rect.height - fillHeight + waveY
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Ripple Transition

public struct RippleTransition: ViewModifier {
    let isPresented: Bool
    let center: UnitPoint
    let rippleCount: Int
    
    @State private var animationProgress: CGFloat = 0
    
    public init(isPresented: Bool, center: UnitPoint = .center, rippleCount: Int = 3) {
        self.isPresented = isPresented
        self.center = center
        self.rippleCount = rippleCount
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                RippleShape(progress: self.animationProgress, center: self.center, rippleCount: self.rippleCount)
            )
            .onAppear {
                withAnimation(AnimationTiming.easeOut) {
                    self.animationProgress = self.isPresented ? 1.0 : 0.0
                }
            }
            .onChange(of: self.isPresented) { newValue in
                withAnimation(AnimationTiming.easeOut) {
                    self.animationProgress = newValue ? 1.0 : 0.0
                }
            }
    }
}

private struct RippleShape: Shape {
    var progress: CGFloat
    let center: UnitPoint
    let rippleCount: Int
    
    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerPoint = CGPoint(
            x: rect.width * self.center.x,
            y: rect.height * self.center.y
        )
        
        let maxRadius = max(
            max(centerPoint.x, rect.width - centerPoint.x),
            max(centerPoint.y, rect.height - centerPoint.y)
        )
        
        for i in 0 ..< self.rippleCount {
            let rippleProgress = max(0, progress * CGFloat(self.rippleCount) - CGFloat(i))
            let rippleRadius = maxRadius * min(1, rippleProgress)
            
            if rippleRadius > 0 {
                path.addEllipse(in: CGRect(
                    x: centerPoint.x - rippleRadius,
                    y: centerPoint.y - rippleRadius,
                    width: rippleRadius * 2,
                    height: rippleRadius * 2
                ))
            }
        }
        
        return path
    }
}

// MARK: - Morphing Transition

public struct MorphTransition<StartShape: Shape, EndShape: Shape>: ViewModifier {
    let isPresented: Bool
    let startShape: StartShape
    let endShape: EndShape
    
    @State private var morphProgress: CGFloat = 0
    
    public init(isPresented: Bool, from startShape: StartShape, to endShape: EndShape) {
        self.isPresented = isPresented
        self.startShape = startShape
        self.endShape = endShape
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                MorphingShape(
                    startShape: self.startShape,
                    endShape: self.endShape,
                    progress: self.morphProgress
                )
            )
            .onAppear {
                withAnimation(AnimationTiming.easeInOut) {
                    self.morphProgress = self.isPresented ? 1.0 : 0.0
                }
            }
            .onChange(of: self.isPresented) { newValue in
                withAnimation(AnimationTiming.easeInOut) {
                    self.morphProgress = newValue ? 1.0 : 0.0
                }
            }
    }
}

private struct MorphingShape<StartShape: Shape, EndShape: Shape>: Shape {
    let startShape: StartShape
    let endShape: EndShape
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        if self.progress <= 0.5 {
            self.startShape.path(in: rect)
        } else {
            self.endShape.path(in: rect)
        }
    }
}

// MARK: - Page Transition Effects

public struct PageCurlTransition: ViewModifier {
    let isPresented: Bool
    let direction: CurlDirection
    
    @State private var curlProgress: CGFloat = 0
    
    public init(isPresented: Bool, direction: CurlDirection = .topRight) {
        self.isPresented = isPresented
        self.direction = direction
    }
    
    public func body(content: Content) -> some View {
        content
            .clipShape(
                PageCurlShape(progress: self.curlProgress, direction: self.direction)
            )
            .onAppear {
                withAnimation(AnimationTiming.easeInOut) {
                    self.curlProgress = self.isPresented ? 1.0 : 0.0
                }
            }
            .onChange(of: self.isPresented) { newValue in
                withAnimation(AnimationTiming.easeInOut) {
                    self.curlProgress = newValue ? 1.0 : 0.0
                }
            }
    }
}

public enum CurlDirection {
    case topLeft, topRight, bottomLeft, bottomRight
}

private struct PageCurlShape: Shape {
    var progress: CGFloat
    let direction: CurlDirection
    
    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let curlSize = min(rect.width, rect.height) * self.progress
        
        switch self.direction {
        case .topRight:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width - curlSize, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: curlSize))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        case .topLeft:
            path.move(to: CGPoint(x: curlSize, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: curlSize))
            path.closeSubpath()
        case .bottomRight:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - curlSize))
            path.addLine(to: CGPoint(x: rect.width - curlSize, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: curlSize, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - curlSize))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Transition Manager

public class TransitionManager: ObservableObject {
    @Published public var currentTransition: TransitionType = .slide(edge: .trailing)
    @Published public var isAnimating = false
    
    public func performTransition(_ transition: TransitionType, duration: Double = 0.5, completion: @escaping () -> Void = {}) {
        self.isAnimating = true
        self.currentTransition = transition
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.isAnimating = false
            completion()
        }
    }
}

// MARK: - View Extensions

public extension View {
    func customTransition(_ type: TransitionType, isPresented: Bool) -> some View {
        Group {
            switch type {
            case let .slide(edge, distance):
                self.modifier(SlideTransitionAdvanced(isPresented: isPresented, edge: edge, distance: distance))
            case let .scale(from, to):
                self.modifier(ScaleTransitionAdvanced(isPresented: isPresented, fromScale: from, toScale: to))
            case let .rotate(degrees):
                self.modifier(RotationTransitionAdvanced(isPresented: isPresented, degrees: degrees))
            case let .flip(axis):
                self.modifier(FlipTransition(isPresented: isPresented, axis: axis))
            case .elastic:
                self.modifier(ElasticTransition(isPresented: isPresented))
            case .bounce:
                self.modifier(BounceTransition(isPresented: isPresented))
            case .iris:
                self.modifier(IrisTransition(isPresented: isPresented))
            case .fan:
                self.modifier(FanTransition(isPresented: isPresented))
            case .liquid:
                self.modifier(LiquidTransition(isPresented: isPresented))
            case .ripple:
                self.modifier(RippleTransition(isPresented: isPresented))
            default:
                self.modifier(ScaleTransitionAdvanced(isPresented: isPresented))
            }
        }
    }
    
    func slideTransitionAdvanced(isPresented: Bool, edge: Edge, distance: CGFloat = 300, overshoot: CGFloat = 50) -> some View {
        modifier(SlideTransitionAdvanced(isPresented: isPresented, edge: edge, distance: distance, overshoot: overshoot))
    }
    
    func scaleTransitionAdvanced(
        isPresented: Bool,
        fromScale: CGFloat = 0.5,
        toScale: CGFloat = 1.0,
        anchor: UnitPoint = .center
    ) -> some View {
        modifier(ScaleTransitionAdvanced(isPresented: isPresented, fromScale: fromScale, toScale: toScale, anchor: anchor))
    }
    
    func flipTransition(isPresented: Bool, axis: FlipAxis = .horizontal) -> some View {
        modifier(FlipTransition(isPresented: isPresented, axis: axis))
    }
    
    func elasticTransition(isPresented: Bool) -> some View {
        modifier(ElasticTransition(isPresented: isPresented))
    }
    
    func bounceTransition(isPresented: Bool) -> some View {
        modifier(BounceTransition(isPresented: isPresented))
    }
    
    func irisTransition(isPresented: Bool, center: UnitPoint = .center) -> some View {
        modifier(IrisTransition(isPresented: isPresented, center: center))
    }
    
    func liquidTransition(isPresented: Bool) -> some View {
        modifier(LiquidTransition(isPresented: isPresented))
    }
    
    func rippleTransition(isPresented: Bool, center: UnitPoint = .center, rippleCount: Int = 3) -> some View {
        modifier(RippleTransition(isPresented: isPresented, center: center, rippleCount: rippleCount))
    }
    
    func pageCurlTransition(isPresented: Bool, direction: CurlDirection = .topRight) -> some View {
        modifier(PageCurlTransition(isPresented: isPresented, direction: direction))
    }
}
