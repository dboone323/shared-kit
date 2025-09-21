import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Micro-interactions for Enhanced User Feedback
/// Provides subtle animations and feedback for user actions
@available(iOS 15.0, macOS 12.0, *)
public struct MicroInteractions {
    // MARK: - Haptic Feedback
    
    public static func lightHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    public static func mediumHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    public static func heavyHaptic() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
    }
    
    // MARK: - Button Interactions
    
    public struct BouncyButton<Content: View>: View {
        let action: () -> Void
        let content: Content
        @State private var isPressed = false
        
        public init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
            self.action = action
            self.content = content()
        }
        
        public var body: some View {
            Button(action: {
                lightHaptic()
                self.action()
            }) {
                self.content
            }
            .scaleEffect(self.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: self.isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in self.isPressed = true }
                    .onEnded { _ in self.isPressed = false }
            )
        }
    }
    
    // MARK: - Loading States
    
    public struct PulsingDot: View {
        @State private var isPulsing = false
        let color: Color
        let size: CGFloat
        
        public init(color: Color = .blue, size: CGFloat = 10) {
            self.color = color
            self.size = size
        }
        
        public var body: some View {
            Circle()
                .fill(self.color)
                .frame(width: self.size, height: self.size)
                .scaleEffect(self.isPulsing ? 1.3 : 1.0)
                .opacity(self.isPulsing ? 0.5 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: self.isPulsing
                )
                .onAppear { self.isPulsing = true }
        }
    }
    
    // MARK: - Success Animations
    
    public struct CheckmarkAnimation: View {
        @State private var progress: CGFloat = 0
        let color: Color
        let size: CGFloat
        
        public init(color: Color = .green, size: CGFloat = 24) {
            self.color = color
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                Circle()
                    .stroke(self.color.opacity(0.3), lineWidth: 2)
                    .frame(width: self.size, height: self.size)
                
                Circle()
                    .trim(from: 0, to: self.progress)
                    .stroke(self.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: self.size, height: self.size)
                    .rotationEffect(.degrees(-90))
                
                if self.progress >= 1.0 {
                    Image(systemName: "checkmark")
                        .foregroundColor(self.color)
                        .font(.system(size: self.size * 0.5, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.progress = 1.0
                }
            }
        }
    }
    
    // MARK: - Floating Action Button
    
    public struct FloatingActionButton: View {
        let action: () -> Void
        let systemImage: String
        @State private var isExpanded = false
        
        public init(systemImage: String = "plus", action: @escaping () -> Void) {
            self.systemImage = systemImage
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                mediumHaptic()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    self.isExpanded.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.action()
                    self.isExpanded = false
                }
            }) {
                Image(systemName: self.systemImage)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.blue)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    )
            }
            .scaleEffect(self.isExpanded ? 1.2 : 1.0)
            .rotation3DEffect(.degrees(self.isExpanded ? 180 : 0), axis: (x: 0, y: 0, z: 1))
        }
    }
}
