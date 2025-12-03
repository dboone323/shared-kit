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
}
