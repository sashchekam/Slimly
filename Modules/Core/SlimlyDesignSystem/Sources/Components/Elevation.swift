import SwiftUI

/// Ступени высоты Nocturne. На тёмном фоне высота — это волосяная кромка
/// плюс окружающая темнота, а не мягкая тень: заливать элемент тенью нельзя,
/// иначе он «всплывает» и ломает плоскую глубину системы.
public enum SlimlyElevation {
    /// Элемент лежит на фоне и рисует границу сам.
    case flat
    case sm
    case md
    case lg

    var edge: Color {
        switch self {
        case .flat: .clear
        case .sm: SlimlyColor.neutral800
        case .md: SlimlyColor.neutral700
        case .lg: SlimlyColor.neutral500
        }
    }

    var shadow: (radius: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .flat, .sm: nil
        case .md: (radius: 9, y: 6, opacity: 0.55)
        case .lg: (radius: 20, y: 16, opacity: 0.65)
        }
    }
}

public extension View {
    func slimlyElevation(_ level: SlimlyElevation, cornerRadius: CGFloat = SlimlyRadius.lg) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return overlay(shape.strokeBorder(level.edge, lineWidth: 1))
            .shadow(
                color: .black.opacity(level.shadow?.opacity ?? 0),
                radius: level.shadow?.radius ?? 0,
                y: level.shadow?.y ?? 0
            )
    }
}

/// Карточка-поверхность: заливка `surface`, скругление и кромка одной ступени.
public struct SlimlyCard<Content: View>: View {
    private let padding: EdgeInsets
    private let cornerRadius: CGFloat
    private let content: Content

    public init(
        padding: EdgeInsets = EdgeInsets(top: 15, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = SlimlyRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SlimlyColor.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .slimlyElevation(.sm, cornerRadius: cornerRadius)
    }
}
