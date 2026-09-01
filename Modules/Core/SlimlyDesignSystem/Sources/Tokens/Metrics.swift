import CoreGraphics

/// Шкала отступов Nocturne. Плотность 0.7× уже заложена в значения —
/// поэтому числа дробные и своих «круглых» рядом заводить не нужно.
public enum SlimlySpacing {
    public static let x1: CGFloat = 2.8
    public static let x2: CGFloat = 5.6
    public static let x3: CGFloat = 8.4
    public static let x4: CGFloat = 11.2
    public static let x6: CGFloat = 16.8
    public static let x8: CGFloat = 22.4

    /// Поля экрана внутри устройства — фиксированы макетом, а не шкалой.
    public static let screenHorizontal: CGFloat = 20
}

public enum SlimlyRadius {
    public static let sm: CGFloat = 4
    public static let md: CGFloat = 8
    public static let lg: CGFloat = 14
    /// Плитки галереи и мелкие превью.
    public static let tile: CGFloat = 10
    public static let thumbnail: CGFloat = 8
    /// Верхние углы нижней шторки.
    public static let sheet: CGFloat = 22
    /// Полностью скруглённые элементы: тумблеры, пилюли, прогресс-полосы.
    public static let pill: CGFloat = 999
}

/// Высота элементов, которые макет задаёт точно.
public enum SlimlySize {
    public static let progressRing: CGFloat = 148
    public static let progressRingWidth: CGFloat = 11
    public static let toggleWidth: CGFloat = 44
    public static let toggleHeight: CGFloat = 26
}
