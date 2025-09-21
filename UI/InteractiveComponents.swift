import SwiftUI

// MARK: - Interactive UI Components

// Sophisticated interactive components for enhanced user experiences across all projects

// MARK: - Interactive Buttons

public struct NeumorphicButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    let isPressed: Bool
    let backgroundColor: Color
    let shadowColor: Color
    
    @State private var isAnimating = false
    
    public init(
        action: @escaping () -> Void,
        backgroundColor: Color = Color(.systemGray6),
        shadowColor: Color = Color.black.opacity(0.2),
        isPressed: Bool = false,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
        self.isPressed = isPressed
        self.label = label()
    }
    
    public var body: some View {
        Button(action: {
            GestureAnimations.hapticFeedback(style: 0)
            withAnimation(AnimationTiming.quick) {
                self.isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.action()
                self.isAnimating = false
            }
        }) {
            self.label
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(self.backgroundColor)
                        .shadow(
                            color: self.shadowColor,
                            radius: self.isAnimating ? 2 : 8,
                            x: self.isAnimating ? 1 : 4,
                            y: self.isAnimating ? 1 : 4
                        )
                        .shadow(
                            color: Color.white.opacity(0.8),
                            radius: self.isAnimating ? 2 : 8,
                            x: self.isAnimating ? -1 : -4,
                            y: self.isAnimating ? -1 : -4
                        )
                )
                .scaleEffect(self.isAnimating ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AnimationTiming.quick, value: self.isAnimating)
    }
}

public struct GlassButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    let backgroundColor: Color
    
    @State private var isPressed = false
    
    public init(
        action: @escaping () -> Void,
        backgroundColor: Color = Color.white.opacity(0.2),
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.backgroundColor = backgroundColor
        self.label = label()
    }
    
    public var body: some View {
        Button(action: {
            GestureAnimations.hapticFeedback(style: 0)
            self.action()
        }) {
            self.label
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(self.backgroundColor)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .scaleEffect(self.isPressed ? 0.95 : 1.0)
                .brightness(self.isPressed ? -0.1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(AnimationTiming.quick) {
                self.isPressed = pressing
            }
        }, perform: {})
    }
}

public struct FloatingActionButton: View {
    let action: () -> Void
    let icon: Image
    let color: Color
    let size: CGFloat
    
    @State private var isPressed = false
    @State private var showRipple = false
    
    public init(
        action: @escaping () -> Void,
        icon: Image = Image(systemName: "plus"),
        color: Color = .blue,
        size: CGFloat = 56
    ) {
        self.action = action
        self.icon = icon
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Ripple effect
            if self.showRipple {
                Circle()
                    .stroke(self.color.opacity(0.4), lineWidth: 2)
                    .scaleEffect(1.8)
                    .opacity(0)
                    .animation(AnimationTiming.easeOut, value: self.showRipple)
            }
            
            Button(action: {
                GestureAnimations.hapticFeedback(style: 1)
                withAnimation(AnimationTiming.quick) {
                    self.showRipple = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showRipple = false
                }
                
                self.action()
            }) {
                self.icon
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white) \ n.frame(width: self.size, height: self.size)
                    .background(
                        Circle()
                            .fill(self.color)
                            .shadow(color: self.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .scaleEffect(self.isPressed ? 0.9 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(AnimationTiming.quick) {
                    self.isPressed = pressing
                }
            }, perform: {})
        }
    }
}

// MARK: - Interactive Cards

public struct InteractiveCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    
    @State private var isPressed = false
    @State private var dragOffset: CGSize = .zero
    
    public init(
        backgroundColor: Color = Color(.systemBackground),
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.content = content()
    }
    
    public var body: some View {
        self.content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: self.cornerRadius)
                    .fill(self.backgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: self.shadowRadius, x: 0, y: 4)
            )
            .scaleEffect(self.isPressed ? 0.98 : 1.0)
            .offset(self.dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.dragOffset = CGSize(width: value.translation.x * 0.1, height: value.translation.y * 0.1)
                    }
                    .onEnded { _ in
                        withAnimation(AnimationTiming.springBouncy) {
                            self.dragOffset = .zero
                        }
                    }
            )
            .onTapGesture {
                self.onTap?()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(AnimationTiming.quick) {
                    self.isPressed = pressing
                }
            }, perform: {
                self.onLongPress?()
            })
            .animation(AnimationTiming.springSmooth, value: self.isPressed)
    }
}

public struct SwipeActionCard<Content: View>: View {
    let content: Content
    let leftActions: [SwipeAction]
    let rightActions: [SwipeAction]
    
    @State private var dragOffset: CGFloat = 0
    @State private var isRevealed = false
    
    public init(
        leftActions: [SwipeAction] = [],
        rightActions: [SwipeAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.leftActions = leftActions
        self.rightActions = rightActions
        self.content = content()
    }
    
    public var body: some View {
        ZStack {
            // Background actions
            HStack {
                if !self.leftActions.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(self.leftActions.indices, id: \.self) { index in
                            SwipeActionView(action: self.leftActions[index])
                        }
                    }
                }
                
                Spacer()
                
                if !self.rightActions.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(self.rightActions.indices, id: \.self) { index in
                            SwipeActionView(action: self.rightActions[index])
                        }
                    }
                }
            }
            
            // Main content
            self.content
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .offset(x: self.dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.x
                            
                            // Limit drag distance
                            if translation > 0, !self.leftActions.isEmpty {
                                self.dragOffset = min(translation, CGFloat(self.leftActions.count * 80))
                            } else if translation < 0, !self.rightActions.isEmpty {
                                self.dragOffset = max(translation, CGFloat(-self.rightActions.count * 80))
                            }
                        }
                        .onEnded { _ in
                            let threshold: CGFloat = 80
                            
                            if abs(self.dragOffset) > threshold {
                                GestureAnimations.hapticFeedback(style: 1)
                            }
                            
                            withAnimation(AnimationTiming.springBouncy) {
                                self.dragOffset = 0
                            }
                        }
                )
        }
    }
}

public struct SwipeAction {
    let title: String
    let icon: Image
    let backgroundColor: Color
    let action: () -> Void
    
    public init(title: String, icon: Image, backgroundColor: Color, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.action = action
    }
}

private struct SwipeActionView: View {
    let action: SwipeAction
    
    var body: some View {
        Button(action: self.action.action) {
            VStack(spacing: 4) {
                self.action.icon
                    .font(.title3)
                Text(self.action.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(width: 80)
            .frame(maxHeight: .infinity)
            .background(self.action.backgroundColor)
        }
    }
}

// MARK: - Interactive Progress Indicators

public struct InteractiveProgressBar: View {
    @Binding var progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let isInteractive: Bool
    
    @State private var dragProgress: Double = 0
    @State private var isDragging = false
    
    public init(
        progress: Binding<Double>,
        height: CGFloat = 8,
        backgroundColor: Color = Color(.systemGray5),
        foregroundColor: Color = .blue,
        isInteractive: Bool = false
    ) {
        self._progress = progress
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isInteractive = isInteractive
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: self.height / 2)
                    .fill(self.backgroundColor)
                    .frame(height: self.height)
                
                // Progress fill
                RoundedRectangle(cornerRadius: self.height / 2)
                    .fill(self.foregroundColor)
                    .frame(width: geometry.size.width * CGFloat(self.isDragging ? self.dragProgress : self.progress), height: self.height)
                    .animation(self.isDragging ? nil : AnimationTiming.easeOut, value: self.progress)
                
                if self.isInteractive {
                    // Interactive overlay
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: self.height * 3) // Larger touch target
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newProgress = Double(value.location.x / geometry.size.width)
                                    self.dragProgress = max(0, min(1, newProgress))
                                    self.isDragging = true
                                    GestureAnimations.hapticFeedback(style: 0)
                                }
                                .onEnded { _ in
                                    self.progress = self.dragProgress
                                    self.isDragging = false
                                }
                        )
                }
            }
        }
        .frame(height: self.height)
    }
}

public struct RadialProgressIndicator: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let showPercentage: Bool
    
    @State private var animatedProgress: Double = 0
    
    public init(
        progress: Double,
        size: CGFloat = 100,
        lineWidth: CGFloat = 8,
        backgroundColor: Color = Color(.systemGray5),
        foregroundColor: Color = .blue,
        showPercentage: Bool = true
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.showPercentage = showPercentage
    }
    
    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(self.backgroundColor, lineWidth: self.lineWidth)
                .frame(width: self.size, height: self.size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(self.animatedProgress))
                .stroke(
                    self.foregroundColor,
                    style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round)
                )
                .frame(width: self.size, height: self.size)
                .rotationEffect(.degrees(-90))
            
            // Percentage text
            if self.showPercentage {
                Text("\(Int(self.animatedProgress * 100))%")
                    .font(.system(size: self.size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(self.foregroundColor)
            }
        }
        .onAppear {
            withAnimation(AnimationTiming.easeOut.delay(0.2)) {
                self.animatedProgress = self.progress
            }
        }
        .onChange(of: self.progress) { newProgress in
            withAnimation(AnimationTiming.easeOut) {
                self.animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Interactive Input Components

public struct InteractiveSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let trackHeight: CGFloat
    let thumbSize: CGFloat
    let trackColor: Color
    let thumbColor: Color
    let fillColor: Color
    
    @State private var isDragging = false
    @State private var dragValue: Double
    
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0 ... 1,
        step: Double = 0.01,
        trackHeight: CGFloat = 6,
        thumbSize: CGFloat = 24,
        trackColor: Color = Color(.systemGray4),
        thumbColor: Color = .white,
        fillColor: Color = .blue
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.trackHeight = trackHeight
        self.thumbSize = thumbSize
        self.trackColor = trackColor
        self.thumbColor = thumbColor
        self.fillColor = fillColor
        self._dragValue = State(initialValue: value.wrappedValue)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - self.thumbSize
            let progress = CGFloat((isDragging ? self.dragValue : self.value) - self.range.lowerBound) /
                CGFloat(self.range.upperBound - self.range.lowerBound)
            let thumbOffset = trackWidth * progress
            
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: self.trackHeight / 2)
                    .fill(self.trackColor)
                    .frame(height: self.trackHeight)
                    .padding(.horizontal, self.thumbSize / 2)
                
                // Fill
                RoundedRectangle(cornerRadius: self.trackHeight / 2)
                    .fill(self.fillColor)
                    .frame(width: thumbOffset + self.thumbSize / 2, height: self.trackHeight)
                    .padding(.leading, self.thumbSize / 2)
                
                // Thumb
                Circle()
                    .fill(self.thumbColor)
                    .frame(width: self.thumbSize, height: self.thumbSize)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .scaleEffect(self.isDragging ? 1.2 : 1.0)
                    .offset(x: thumbOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newOffset = max(0, min(trackWidth, gesture.location.x - self.thumbSize / 2))
                                let newProgress = Double(newOffset / trackWidth)
                                let newValue = self.range.lowerBound + (self.range.upperBound - self.range.lowerBound) * newProgress
                                
                                self.dragValue = (newValue / self.step).rounded() * self.step
                                self.dragValue = max(self.range.lowerBound, min(self.range.upperBound, self.dragValue))
                                
                                if !self.isDragging {
                                    self.isDragging = true
                                    GestureAnimations.hapticFeedback(style: 0)
                                }
                            }
                            .onEnded { _ in
                                self.value = self.dragValue
                                self.isDragging = false
                            }
                    )
                    .animation(AnimationTiming.springSmooth, value: self.isDragging)
            }
        }
        .frame(height: max(self.trackHeight, self.thumbSize))
    }
}

public struct InteractiveToggle: View {
    @Binding var isOn: Bool
    let size: CGSize
    let onColor: Color
    let offColor: Color
    let thumbColor: Color
    
    @State private var isAnimating = false
    
    public init(
        isOn: Binding<Bool>,
        size: CGSize = CGSize(width: 50, height: 30),
        onColor: Color = .green,
        offColor: Color = Color(.systemGray4),
        thumbColor: Color = .white
    ) {
        self._isOn = isOn
        self.size = size
        self.onColor = onColor
        self.offColor = offColor
        self.thumbColor = thumbColor
    }
    
    public var body: some View {
        Button(action: {
            GestureAnimations.hapticFeedback(style: 0)
            withAnimation(AnimationTiming.springBouncy) {
                self.isOn.toggle()
                self.isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isAnimating = false
            }
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: self.size.height / 2)
                    .fill(self.isOn ? self.onColor : self.offColor)
                    .frame(width: self.size.width, height: self.size.height)
                
                // Thumb
                Circle()
                    .fill(self.thumbColor)
                    .frame(width: self.size.height - 4, height: self.size.height - 4)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .scaleEffect(self.isAnimating ? 1.1 : 1.0)
                    .offset(x: self.isOn ? (self.size.width - self.size.height) / 2 : -(self.size.width - self.size.height) / 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Interactive Navigation Components

public struct TabBarItem: View {
    let title: String
    let icon: Image
    let selectedIcon: Image?
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    public init(
        title: String,
        icon: Image,
        selectedIcon: Image? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            GestureAnimations.hapticFeedback(style: 0)
            self.action()
        }) {
            VStack(spacing: 4) {
                (self.isSelected ? (self.selectedIcon ?? self.icon) : self.icon)
                    .font(.system(size: 24))
                    .foregroundColor(self.isSelected ? .primary : .secondary)
                    .scaleEffect(self.isPressed ? 0.9 : (self.isSelected ? 1.1 : 1.0))
                
                Text(self.title)
                    .font(.caption)
                    .fontWeight(self.isSelected ? .semibold : .regular)
                    .foregroundColor(self.isSelected ? .primary : .secondary)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(AnimationTiming.quick) {
                self.isPressed = pressing
            }
        }, perform: {})
        .animation(AnimationTiming.springSmooth, value: self.isSelected)
    }
}

public struct InteractiveTabBar: View {
    let items: [TabBarItemData]
    @Binding var selectedIndex: Int
    let backgroundColor: Color
    let shadowColor: Color
    
    public init(
        items: [TabBarItemData],
        selectedIndex: Binding<Int>,
        backgroundColor: Color = Color(.systemBackground),
        shadowColor: Color = Color.black.opacity(0.1)
    ) {
        self.items = items
        self._selectedIndex = selectedIndex
        self.backgroundColor = backgroundColor
        self.shadowColor = shadowColor
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(self.items.indices, id: \.self) { index in
                TabBarItem(
                    title: self.items[index].title,
                    icon: self.items[index].icon,
                    selectedIcon: self.items[index].selectedIcon,
                    isSelected: self.selectedIndex == index,
                    action: {
                        self.selectedIndex = index
                        self.items[index].action()
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .background(
            self.backgroundColor
                .shadow(color: self.shadowColor, radius: 8, x: 0, y: -2)
        )
    }
}

public struct TabBarItemData {
    let title: String
    let icon: Image
    let selectedIcon: Image?
    let action: () -> Void
    
    public init(title: String, icon: Image, selectedIcon: Image? = nil, action: @escaping () -> Void = {}) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.action = action
    }
}

// MARK: - View Extensions

public extension View {
    func interactiveCard(
        backgroundColor: Color = Color(.systemBackground),
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) -> some View {
        InteractiveCard(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            onTap: onTap,
            onLongPress: onLongPress
        ) {
            self
        }
    }
}
