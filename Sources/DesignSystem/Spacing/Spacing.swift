import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// Shared spacing system for consistent layout across all projects
public struct Spacing {
    // MARK: - Spacing Scale
    
    /// Extra extra small spacing (2pt)
    public static let xxs: CGFloat = 2
    
    /// Extra small spacing (4pt)
    public static let xs: CGFloat = 4
    
    /// Small spacing (8pt)
    public static let sm: CGFloat = 8
    
    /// Medium spacing (16pt) - Base unit
    public static let md: CGFloat = 16
    
    /// Large spacing (24pt)
    public static let lg: CGFloat = 24
    
    /// Extra large spacing (32pt)
    public static let xl: CGFloat = 32
    
    /// 2x extra large spacing (48pt)
    public static let xl2: CGFloat = 48
    
    /// 3x extra large spacing (64pt)
    public static let xl3: CGFloat = 64
    
    /// 4x extra large spacing (96pt)
    public static let xl4: CGFloat = 96
    
    // MARK: - Common Use Cases
    
    /// Spacing for list item padding
    public static let listItemPadding: CGFloat = md
    
    /// Spacing between sections
    public static let sectionSpacing: CGFloat = xl
    
    /// Card padding
    public static let cardPadding: CGFloat = md
    
    /// Screen edge padding
    public static let screenPadding: CGFloat = lg
}
