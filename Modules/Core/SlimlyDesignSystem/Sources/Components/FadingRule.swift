import SwiftUI

/// Подпись Nocturne: линейки гаснут к краям, а не обрываются.
///
/// Растушёвка занимает по 18% ширины с каждой стороны — так линия читается
/// как акцентная метка под блоком, а не как рамка.
public struct SlimlyFadingRule: View {
    private let color: Color

    public init(color: Color = SlimlyColor.accent600) {
        self.color = color
    }

    public var body: some View {
        LinearGradient(
            stops: [
                .init(color: color.opacity(0), location: 0),
                .init(color: color, location: 0.18),
                .init(color: color, location: 0.82),
                .init(color: color.opacity(0), location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}

/// Вертикальный разделитель между колонками показателей — гаснет к торцам.
public struct SlimlyColumnDivider: View {
    public init() { }

    public var body: some View {
        LinearGradient(
            stops: [
                .init(color: SlimlyColor.text.opacity(0), location: 0),
                .init(color: SlimlyColor.text.opacity(0.15), location: 0.5),
                .init(color: SlimlyColor.text.opacity(0), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: 1)
    }
}
