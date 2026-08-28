import SwiftUI

public enum SlimlyColor {
    public static let accent = Color(red: 0.29, green: 0.78, blue: 0.55)
    public static let accentSoft = Color(red: 0.29, green: 0.78, blue: 0.55).opacity(0.14)
    public static let background = Color(uiColor: .systemBackground)
    public static let surface = Color(uiColor: .secondarySystemBackground)
    public static let textPrimary = Color(uiColor: .label)
    public static let textSecondary = Color(uiColor: .secondaryLabel)
}

public enum SlimlySpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
}

public enum SlimlyRadius {
    public static let button: CGFloat = 16
    public static let card: CGFloat = 20
}

public extension Font {
    static let slimlyTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let slimlySubtitle = Font.system(size: 17, weight: .regular, design: .rounded)
    static let slimlyButton = Font.system(size: 17, weight: .semibold, design: .rounded)
}
