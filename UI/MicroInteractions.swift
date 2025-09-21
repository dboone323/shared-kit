import Combine
import SwiftUI

// MARK: - Micro-Interactions System

// Delightful micro-interactions and advanced gesture handling for enhanced user experiences

// MARK: - Micro-Interaction Components

public struct MicroInteractionButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let feedbackStyle: Int
    let scaleEffect: CGFloat
    let glowColor: Color?
    
    @State private var isPressed = false
    @State private var showGlow = false
    
    public init(
        feedbackStyle: Int = 1,
        scaleEffect: CGFloat = 0.95,
        glowColor: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.feedbackStyle = feedbackStyle
        self.scaleEffect = scaleEffect
        self.glowColor = glowColor
    }
    
    public var body: some View {
        self.content
            .scaleEffect(self.isPressed ? self.scaleEffect : 1.0)
            .brightness(self.isPressed ? -0.1 : 0)
            .shadow(
                color: self.showGlow ? (self.glowColor ?? .blue) : .clear,
                radius: self.showGlow ? 8 : 0
            )
            .onTapGesture {
                self.performMicroInteraction()
                self.action()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(AnimationTiming.quick) {
                    self.isPressed = pressing
                    if pressing {
                        self.showGlow = self.glowColor != nil
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.showGlow = false
                        }
                    }
                }
            }, perform: {})
    }
    
    private func performMicroInteraction() {
        GestureAnimations.hapticFeedback(style: self.feedbackStyle)
        
        withAnimation(AnimationTiming.springBouncy) {
            self.showGlow = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AnimationTiming.easeOut) {
                self.showGlow = false
            }
        }
    }
}

public struct PressAndHoldButton<Content: View>: View {
    let content: Content
    let duration: TimeInterval
    let onProgress: (Double) -> Void
    let onComplete: () -> Void
    
    @State private var isPressed = false
    @State private var progress: Double = 0
    @State private var timer: Timer?
    
    public init(
        duration: TimeInterval = 2.0,
        onProgress: @escaping (Double) -> Void = { _ in },
        onComplete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.duration = duration
        self.onProgress = onProgress
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            // Progress background
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            // Progress indicator
            Circle()
                .trim(from: 0, to: CGFloat(self.progress))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(AnimationTiming.quick, value: self.progress)
            
            self.content
                .scaleEffect(self.isPressed ? 0.9 : 1.0)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !self.isPressed {
                        self.startProgress()
                    }
                }
                .onEnded { _ in
                    self.stopProgress()
                }
        )
    }
    
    private func startProgress() {
        self.isPressed = true
        self.progress = 0
        GestureAnimations.hapticFeedback(style: 0)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.progress += 0.05 / self.duration
            self.onProgress(self.progress)
            
            if self.progress >= 1.0 {
                self.completeAction()
            }
        }
    }
    
    private func stopProgress() {
        self.isPressed = false
        self.timer?.invalidate()
        self.timer = nil
        
        withAnimation(AnimationTiming.easeOut) {
            self.progress = 0
        }
    }
    
    private func completeAction() {
        self.timer?.invalidate()
        self.timer = nil
        self.isPressed = false
        
        GestureAnimations.hapticFeedback(style: 2)
        self.onComplete()
        
        withAnimation(AnimationTiming.easeOut) {
            self.progress = 0
        }
    }
}

public struct SwipeGestureArea<Content: View>: View {
    let content: Content
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    let onSwipeUp: (() -> Void)?
    let onSwipeDown: (() -> Void)?
    let threshold: CGFloat
    
    @State private var dragOffset: CGSize = .zero
    @State private var showDirectionHint = false
    @State private var swipeDirection: SwipeDirection?
    
    public init(
        threshold: CGFloat = 100,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        onSwipeDown: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.threshold = threshold
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.onSwipeUp = onSwipeUp
        self.onSwipeDown = onSwipeDown
    }
    
    public var body: some View {
        ZStack {
            self.content
                .offset(self.dragOffset)
            
            // Direction hint
            if self.showDirectionHint, let direction = swipeDirection {
                SwipeDirectionHint(direction: direction)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.dragOffset = CGSize(
                        width: value.translation.x * 0.3,
                        height: value.translation.y * 0.3
                    )
                    
                    let direction = self.getSwipeDirection(from: value.translation)
                    if direction != self.swipeDirection {
                        self.swipeDirection = direction
                        withAnimation(AnimationTiming.quick) {
                            self.showDirectionHint = abs(value.translation.x) > self.threshold / 2 || abs(value.translation.y) > self
                                .threshold / 2
                        }
                    }
                }
                .onEnded { value in
                    let translation = value.translation
                    
                    withAnimation(AnimationTiming.springBouncy) {
                        self.dragOffset = .zero
                        self.showDirectionHint = false
                    }
                    
                    if abs(translation.x) > self.threshold || abs(translation.y) > self.threshold {
                        GestureAnimations.hapticFeedback(style: 1)
                        
                        if abs(translation.x) > abs(translation.y) {
                            if translation.x > 0 {
                                self.onSwipeRight?()
                            } else {
                                self.onSwipeLeft?()
                            }
                        } else {
                            if translation.y > 0 {
                                self.onSwipeDown?()
                            } else {
                                self.onSwipeUp?()
                            }
                        }
                    }
                    
                    self.swipeDirection = nil
                }
        )
    }
    
    private func getSwipeDirection(from translation: CGSize) -> SwipeDirection? {
        if abs(translation.x) > abs(translation.y) {
            translation.x > 0 ? .right : .left
        } else {
            translation.y > 0 ? .down : .up
        }
    }
}

private enum SwipeDirection {
    case left, right, up, down
}

private struct SwipeDirectionHint: View {
    let direction: SwipeDirection
    
    var body: some View {
        Image(systemName: self.arrowIcon)
            .font(.title)
            .foregroundColor(.blue)
            .padding()
            .background(
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .background(.ultraThinMaterial, in: Circle())
            )
    }
    
    private var arrowIcon: String {
        switch self.direction {
        case .left: "arrow.left"
        case .right: "arrow.right"
        case .up: "arrow.up"
        case .down: "arrow.down"
        }
    }
}

// MARK: - Advanced Gesture Recognizers

public struct PinchToZoomModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    let minScale: CGFloat
    let maxScale: CGFloat
    let onScaleChange: (CGFloat) -> Void
    
    public init(minScale: CGFloat = 0.5, maxScale: CGFloat = 3.0, onScaleChange: @escaping (CGFloat) -> Void = { _ in }) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.onScaleChange = onScaleChange
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(self.scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = self.lastScale * value
                        self.scale = max(self.minScale, min(self.maxScale, newScale))
                        self.onScaleChange(self.scale)
                    }
                    .onEnded { _ in
                        self.lastScale = self.scale
                        GestureAnimations.hapticFeedback(style: 0)
                    }
            )
            .animation(AnimationTiming.springSmooth, value: self.scale)
    }
}

public struct RotationGestureModifier: ViewModifier {
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    
    let onRotationChange: (Angle) -> Void
    
    public init(onRotationChange: @escaping (Angle) -> Void = { _ in }) {
        self.onRotationChange = onRotationChange
    }
    
    public func body(content: Content) -> some View {
        content
            .rotationEffect(self.rotation)
            .gesture(
                RotationGesture()
                    .onChanged { value in
                        self.rotation = self.lastRotation + value
                        self.onRotationChange(self.rotation)
                    }
                    .onEnded { _ in
                        self.lastRotation = self.rotation
                        GestureAnimations.hapticFeedback(style: 0)
                    }
            )
            .animation(AnimationTiming.springSmooth, value: self.rotation)
    }
}

public struct MultiTouchGestureArea<Content: View>: View {
    let content: Content
    let onSingleTap: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    let onTripleTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    
    @State private var tapCount = 0
    @State private var tapTimer: Timer?
    
    public init(
        onSingleTap: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil,
        onTripleTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onSingleTap = onSingleTap
        self.onDoubleTap = onDoubleTap
        self.onTripleTap = onTripleTap
        self.onLongPress = onLongPress
    }
    
    public var body: some View {
        self.content
            .onTapGesture {
                self.handleTap()
            }
            .onLongPressGesture {
                self.onLongPress?()
                GestureAnimations.hapticFeedback(style: 1)
            }
    }
    
    private func handleTap() {
        self.tapCount += 1
        self.tapTimer?.invalidate()
        
        self.tapTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            switch self.tapCount {
            case 1:
                self.onSingleTap?()
                GestureAnimations.hapticFeedback(style: 0)
            case 2:
                self.onDoubleTap?()
                GestureAnimations.hapticFeedback(style: 1)
            case 3:
                self.onTripleTap?()
                GestureAnimations.hapticFeedback(style: 2)
            default:
                break
            }
            self.tapCount = 0
        }
    }
}

// MARK: - Interactive Feedback Components

public struct VibrantButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let vibrantColor: Color
    
    @State private var isPressed = false
    @State private var showVibration = false
    
    public init(
        vibrantColor: Color = .blue,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.vibrantColor = vibrantColor
    }
    
    public var body: some View {
        self.content
            .scaleEffect(self.isPressed ? 0.95 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(self.vibrantColor, lineWidth: self.showVibration ? 2 : 0)
                    .scaleEffect(self.showVibration ? 1.1 : 1.0)
                    .opacity(self.showVibration ? 0.8 : 0)
            )
            .onTapGesture {
                self.performVibrantFeedback()
                self.action()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(AnimationTiming.quick) {
                    self.isPressed = pressing
                }
            }, perform: {})
    }
    
    private func performVibrantFeedback() {
        GestureAnimations.hapticFeedback(style: 1)
        
        withAnimation(AnimationTiming.springBouncy) {
            self.showVibration = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(AnimationTiming.easeOut) {
                self.showVibration = false
            }
        }
    }
}

public struct MagneticButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let magneticRadius: CGFloat
    
    @State private var offset: CGSize = .zero
    @State private var isAttracting = false
    
    public init(
        magneticRadius: CGFloat = 50,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.magneticRadius = magneticRadius
    }
    
    public var body: some View {
        self.content
            .offset(self.offset)
            .scaleEffect(self.isAttracting ? 1.05 : 1.0)
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .onChanged { value in
                        let distance = sqrt(pow(value.location.x, 2) + pow(value.location.y, 2))
                        
                        if distance < self.magneticRadius {
                            let attraction = 1 - (distance / self.magneticRadius)
                            self.offset = CGSize(
                                width: value.location.x * attraction * 0.3,
                                height: value.location.y * attraction * 0.3
                            )
                            
                            if !self.isAttracting {
                                self.isAttracting = true
                                GestureAnimations.hapticFeedback(style: 0)
                            }
                        } else {
                            withAnimation(AnimationTiming.springBouncy) {
                                self.offset = .zero
                                self.isAttracting = false
                            }
                        }
                    }
                    .onEnded { _ in
                        if self.isAttracting {
                            self.action()
                            GestureAnimations.hapticFeedback(style: 1)
                        }
                        
                        withAnimation(AnimationTiming.springBouncy) {
                            self.offset = .zero
                            self.isAttracting = false
                        }
                    }
            )
            .animation(AnimationTiming.springSmooth, value: self.isAttracting)
    }
}

// MARK: - Contextual Interactions

public struct ContextMenuInteraction<Content: View, MenuContent: View>: View {
    let content: Content
    let menuContent: MenuContent
    let previewContent: Content?
    
    @State private var showingPreview = false
    @State private var showingMenu = false
    @State private var pressLocation: CGPoint = .zero
    
    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder menuContent: () -> MenuContent,
        @ViewBuilder previewContent: (() -> Content)? = nil
    ) {
        self.content = content()
        self.menuContent = menuContent()
        self.previewContent = previewContent?()
    }
    
    public var body: some View {
        self.content
            .scaleEffect(self.showingPreview ? 1.05 : 1.0)
            .blur(radius: self.showingPreview ? 1 : 0)
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                withAnimation(AnimationTiming.springBouncy) {
                    self.showingMenu = true
                }
                GestureAnimations.hapticFeedback(style: 2)
            }
            .onLongPressGesture(minimumDuration: 0.2, maximumDistance: 50, pressing: { pressing in
                withAnimation(AnimationTiming.quick) {
                    self.showingPreview = pressing
                }
                if pressing {
                    GestureAnimations.hapticFeedback(style: 0)
                }
            }, perform: {})
            .overlay(
                Group {
                    if self.showingMenu {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(AnimationTiming.easeOut) {
                                    self.showingMenu = false
                                }
                            }
                        
                        VStack {
                            if let preview = previewContent {
                                preview
                                    .scaleEffect(0.8)
                                    .cornerRadius(12)
                                    .shadow(radius: 20)
                            }
                            
                            self.menuContent
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .padding()
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            )
    }
}

public struct FluidInteractionArea<Content: View>: View {
    let content: Content
    let onInteraction: (InteractionType, CGPoint) -> Void
    
    @State private var lastTouchPoint: CGPoint = .zero
    @State private var ripples: [RippleEffect] = []
    
    public init(
        onInteraction: @escaping (InteractionType, CGPoint) -> Void = { _, _ in },
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onInteraction = onInteraction
    }
    
    public var body: some View {
        ZStack {
            self.content
            
            // Ripple effects
            ForEach(self.ripples, id: \.id) { ripple in
                Circle()
                    .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                    .frame(width: ripple.radius * 2, height: ripple.radius * 2)
                    .position(ripple.position)
                    .opacity(ripple.opacity)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    self.lastTouchPoint = value.location
                    self.onInteraction(.drag, value.location)
                }
                .onEnded { value in
                    self.onInteraction(.end, value.location)
                    self.createRipple(at: value.location)
                }
        )
        .onTapGesture { location in
            self.onInteraction(.tap, location)
            self.createRipple(at: location)
        }
    }
    
    private func createRipple(at point: CGPoint) {
        let ripple = RippleEffect(position: point)
        self.ripples.append(ripple)
        
        withAnimation(.easeOut(duration: 0.8)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                self.ripples[index].radius = 50
                self.ripples[index].opacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.ripples.removeAll { $0.id == ripple.id }
        }
    }
}

public enum InteractionType {
    case tap, drag, end
}

private struct RippleEffect {
    let id = UUID()
    let position: CGPoint
    var radius: CGFloat = 5
    var opacity: Double = 1.0
}

// MARK: - View Extensions

public extension View {
    func microInteractionButton(
        feedbackStyle: Int = 1,
        scaleEffect: CGFloat = 0.95,
        glowColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        MicroInteractionButton(
            feedbackStyle: feedbackStyle,
            scaleEffect: scaleEffect,
            glowColor: glowColor,
            action: action
        ) {
            self
        }
    }
    
    func swipeGestures(
        threshold: CGFloat = 100,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        onSwipeDown: (() -> Void)? = nil
    ) -> some View {
        SwipeGestureArea(
            threshold: threshold,
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown
        ) {
            self
        }
    }
    
    func pinchToZoom(
        minScale: CGFloat = 0.5,
        maxScale: CGFloat = 3.0,
        onScaleChange: @escaping (CGFloat) -> Void = { _ in }
    ) -> some View {
        modifier(PinchToZoomModifier(minScale: minScale, maxScale: maxScale, onScaleChange: onScaleChange))
    }
    
    func rotationGesture(onRotationChange: @escaping (Angle) -> Void = { _ in }) -> some View {
        modifier(RotationGestureModifier(onRotationChange: onRotationChange))
    }
    
    func multiTouchGestures(
        onSingleTap: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil,
        onTripleTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) -> some View {
        MultiTouchGestureArea(
            onSingleTap: onSingleTap,
            onDoubleTap: onDoubleTap,
            onTripleTap: onTripleTap,
            onLongPress: onLongPress
        ) {
            self
        }
    }
    
    func vibrantButton(
        vibrantColor: Color = .blue,
        action: @escaping () -> Void
    ) -> some View {
        VibrantButton(vibrantColor: vibrantColor, action: action) {
            self
        }
    }
    
    func magneticButton(
        magneticRadius: CGFloat = 50,
        action: @escaping () -> Void
    ) -> some View {
        MagneticButton(magneticRadius: magneticRadius, action: action) {
            self
        }
    }
    
    func fluidInteraction(onInteraction: @escaping (InteractionType, CGPoint) -> Void = { _, _ in }) -> some View {
        FluidInteractionArea(onInteraction: onInteraction) {
            self
        }
    }
}
