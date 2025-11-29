//
// CardView.swift
// SharedKit
//
// Standard card container for all apps
//

import SwiftUI

public struct CardView<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding()
            .background(Color("CardBackground", bundle: .module))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
