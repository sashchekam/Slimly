import SwiftUI

/// Диагональная штриховка вместо превью файла.
///
/// Настоящих миниатюр в макете нет, и это осознанно: пока библиотека
/// не подключена, штриховка честнее серого прямоугольника — видно, что
/// это заглушка, а не «не загрузилось».
public struct SlimlyStripes: View {
    private let light: Color
    private let dark: Color
    private let band: CGFloat

    public init(light: Color, dark: Color, band: CGFloat) {
        self.light = light
        self.dark = dark
        self.band = band
    }

    /// Плитка галереи.
    public static var tile: SlimlyStripes {
        SlimlyStripes(light: SlimlyColor.stripeLight, dark: SlimlyColor.stripeDark, band: 7)
    }

    /// Миниатюра в строке списка.
    public static var thumbnail: SlimlyStripes {
        SlimlyStripes(light: SlimlyColor.stripeThumbLight, dark: SlimlyColor.stripeThumbDark, band: 6)
    }

    public var body: some View {
        dark.overlay(DiagonalBands(band: band).fill(light))
    }
}

private struct DiagonalBands: Shape {
    let band: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let period = band * 2
        var offset = -rect.height

        while offset < rect.width {
            path.move(to: CGPoint(x: offset, y: rect.maxY))
            path.addLine(to: CGPoint(x: offset + rect.height, y: rect.minY))
            path.addLine(to: CGPoint(x: offset + rect.height + band, y: rect.minY))
            path.addLine(to: CGPoint(x: offset + band, y: rect.maxY))
            path.closeSubpath()
            offset += period
        }
        return path
    }
}
