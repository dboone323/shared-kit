//
// ThemeColors.swift
// SharedKit
//
// Standard color palette
//

import SwiftUI

public enum ThemeColors {
    public static let primary = Color.blue
    public static let secondary = Color.gray
    public static let success = Color.green
    public static let warning = Color.orange
    public static let error = Color.red

    public static let background = Color("Background", bundle: .module)
    public static let cardBackground = Color("CardBackground", bundle: .module)
}
