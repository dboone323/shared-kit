import SwiftUI

/// Shared color palette for consistent theming across all projects
public enum ColorPalette {
    // MARK: - Primary Colors

    /// Primary shade variations
    public static let primary50 = Color(hex: "E3F2FD")
    public static let primary100 = Color(hex: "BBDEFB")
    public static let primary500 = Color(hex: "2196F3")
    public static let primary700 = Color(hex: "1976D2")
    public static let primary900 = Color(hex: "0D47A1")

    // MARK: - Semantic Colors

    /// Success state color (green)
    public static let success = Color(hex: "4CAF50")

    /// Warning state color (orange)
    public static let warning = Color(hex: "FF9800")

    /// Error state color (red)
    public static let error = Color(hex: "F44336")

    /// Informational color (blue)
    public static let info = Color(hex: "2196F3")

    // MARK: - Neutral Colors

    /// Lightest gray for backgrounds
    public static let gray50 = Color(hex: "FAFAFA")
    public static let gray100 = Color(hex: "F5F5F5")
    public static let gray200 = Color(hex: "EEEEEE")
    public static let gray300 = Color(hex: "E0E0E0")
    public static let gray500 = Color(hex: "9E9E9E")
    public static let gray700 = Color(hex: "616161")
    public static let gray900 = Color(hex: "212121")

    // MARK: - App-Specific Accent Colors

    /// AvoidObstaclesGame - Vibrant orange/red for action
    public enum Game {
        public static let accent = Color(hex: "FF5722")
        public static let accentLight = Color(hex: "FF8A65")
        public static let accentDark = Color(hex: "E64A19")
        public static let glow = Color(hex: "FFAB91")
        public static let obstacle = Color(hex: "B71C1C")
        public static let powerUp = Color(hex: "FFD600")
    }

    /// HabitQuest - Energetic purple/violet for gamification
    public enum Habit {
        public static let accent = Color(hex: "7C4DFF")
        public static let accentLight = Color(hex: "B388FF")
        public static let accentDark = Color(hex: "651FFF")
        public static let xp = Color(hex: "FFD700")
        public static let streak = Color(hex: "FF6D00")
        public static let complete = Color(hex: "00E676")
    }

    /// MomentumFinance - Professional teal/green
    public enum Finance {
        public static let accent = Color(hex: "00BFA5")
        public static let accentLight = Color(hex: "64FFDA")
        public static let accentDark = Color(hex: "00897B")
        public static let positive = Color(hex: "00C853")
        public static let negative = Color(hex: "FF5252")
        public static let neutral = Color(hex: "78909C")
    }

    /// PlannerApp - Calm blue for productivity
    public enum Planner {
        public static let accent = Color(hex: "448AFF")
        public static let accentLight = Color(hex: "82B1FF")
        public static let accentDark = Color(hex: "2962FF")
        public static let highPriority = Color(hex: "FF1744")
        public static let medPriority = Color(hex: "FFC400")
        public static let lowPriority = Color(hex: "00E676")
    }

    /// CodingReviewer - Hacker green/cyan
    public enum Code {
        public static let accent = Color(hex: "00E5FF")
        public static let accentLight = Color(hex: "84FFFF")
        public static let accentDark = Color(hex: "00B8D4")
        public static let syntax = Color(hex: "C6FF00")
        public static let errorHighlight = Color(hex: "FF5252")
        public static let suggestionHighlight = Color(hex: "FFD740")
    }
}

// MARK: - Adaptive Colors (Dark Mode Support)

public enum AdaptiveColors {
    /// Background color that adapts to dark/light mode
    public static var background: Color {
        Color(light: ColorPalette.gray50, dark: Color(hex: "121212"))
    }

    /// Secondary background for cards/elevated surfaces
    public static var backgroundSecondary: Color {
        Color(light: .white, dark: Color(hex: "1E1E1E"))
    }

    /// Tertiary background for nested elements
    public static var backgroundTertiary: Color {
        Color(light: ColorPalette.gray100, dark: Color(hex: "2C2C2C"))
    }

    /// Primary text color
    public static var textPrimary: Color {
        Color(light: ColorPalette.gray900, dark: .white)
    }

    /// Secondary text color
    public static var textSecondary: Color {
        Color(light: ColorPalette.gray700, dark: ColorPalette.gray300)
    }

    /// Tertiary/disabled text color
    public static var textTertiary: Color {
        Color(light: ColorPalette.gray500, dark: ColorPalette.gray500)
    }

    /// Border/separator color
    public static var border: Color {
        Color(light: ColorPalette.gray200, dark: Color(hex: "3C3C3C"))
    }

    /// Shadow color for elevated elements
    public static var shadow: Color {
        Color(light: .black.opacity(0.1), dark: .black.opacity(0.3))
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "FF0000" or "#FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Initialize Color with separate light and dark mode colors
    /// - Parameters:
    ///   - light: Color for light mode
    ///   - dark: Color for dark mode
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}

