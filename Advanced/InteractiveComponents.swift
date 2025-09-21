import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Interactive UI Components for Enhanced User Experience
/// Provides advanced interactive elements with gesture support
@available(iOS 15.0, macOS 12.0, *)
public struct InteractiveComponents {
    // MARK: - Interactive Button
    
    public struct InteractiveButton<Content: View>: View {
        let action: () -> Void
        let content: Content
        @State private var isPressed = false
        @State private var scale: CGFloat = 1.0
        
        public init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
            self.action = action
            self.content = content()
        }
        
        public var body: some View {
            self.content
                .scaleEffect(self.scale)
                .opacity(self.isPressed ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: self.scale)
                .animation(.easeInOut(duration: 0.2), value: self.isPressed)
                .onTapGesture {
                    self.action()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            self.isPressed = true
                            self.scale = 0.95
                        }
                        .onEnded { _ in
                            self.isPressed = false
                            self.scale = 1.0
                        }
                )
        }
    }
    
    // MARK: - Swipeable Card
    
    public struct SwipeableCard<Content: View>: View {
        let content: Content
        let onSwipeLeft: (() -> Void)?
        let onSwipeRight: (() -> Void)?
        @State private var offset = CGSize.zero
        @State private var rotation: Double = 0
        
        public init(
            onSwipeLeft: (() -> Void)? = nil,
            onSwipeRight: (() -> Void)? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeRight = onSwipeRight
            self.content = content()
        }
        
        public var body: some View {
            self.content
                .offset(self.offset)
                .rotationEffect(.degrees(self.rotation))
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            self.offset = gesture.translation
                            self.rotation = Double(gesture.translation.width / 20)
                        }
                        .onEnded { gesture in
                            if abs(gesture.translation.width) > 100 {
                                if gesture.translation.width > 0 {
                                    self.onSwipeRight?()
                                } else {
                                    self.onSwipeLeft?()
                                }
                            }
                            
                            withAnimation(.spring()) {
                                self.offset = .zero
                                self.rotation = 0
                            }
                        }
                )
        }
    }
    
    // MARK: - Draggable Element
    
    public struct DraggableElement<Content: View>: View {
        let content: Content
        @State private var position = CGPoint(x: 100, y: 100)
        @State private var isDragging = false
        
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            self.content
                .position(self.position)
                .scaleEffect(self.isDragging ? 1.1 : 1.0)
                .shadow(radius: self.isDragging ? 10 : 5)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: self.isDragging)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { gesture in
                            self.isDragging = true
                            self.position = gesture.location
                        }
                        .onEnded { _ in
                            self.isDragging = false
                        }
                )
        }
    }
}
