import SwiftUI

/// Горизонтальная полоса прогресса.
public struct SlimlyProgressBar: View {
    /// Толстые полосы-итоги заливаются градиентом рампы, тонкие строчные —
    /// сплошным акцентом: на трёх пунктах высоты градиент всё равно не читается.
    public enum Fill: Sendable { case gradient, solid }

    private let value: Double
    private let height: CGFloat
    private let fill: Fill

    public init(value: Double, height: CGFloat = 7, fill: Fill = .gradient) {
        self.value = value
        self.height = height
        self.fill = fill
    }

    public var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(style)
                .frame(width: proxy.size.width * value.clampedToUnitInterval)
        }
        .frame(height: height)
        .background(SlimlyColor.neutral900, in: Capsule())
    }

    private var style: AnyShapeStyle {
        switch fill {
        case .gradient:
            AnyShapeStyle(
                LinearGradient(
                    colors: [SlimlyColor.accent500, SlimlyColor.accent600],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .solid:
            AnyShapeStyle(SlimlyColor.accent)
        }
    }
}

/// Кольцо прогресса на экране обработки: акцентная дуга по тёмному ободу
/// и утопленный центр с процентом.
public struct SlimlyProgressRing<Label: View>: View {
    private let value: Double
    private let label: Label

    public init(value: Double, @ViewBuilder label: () -> Label) {
        self.value = value
        self.label = label()
    }

    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(SlimlyColor.neutral900, lineWidth: SlimlySize.progressRingWidth)

            Circle()
                .inset(by: SlimlySize.progressRingWidth / 2)
                .trim(from: 0, to: value.clampedToUnitInterval)
                .stroke(SlimlyColor.accent, lineWidth: SlimlySize.progressRingWidth)
                .rotationEffect(.degrees(-90))
                // Анимируем только дугу: под общей анимацией цифра процента
                // на каждом шаге перекрёстно растворялась и мазалась.
                .animation(.linear(duration: 0.2), value: value)

            Circle()
                .fill(SlimlyColor.surfaceSunken)
                .padding(SlimlySize.progressRingWidth)

            label
        }
        .frame(width: SlimlySize.progressRing, height: SlimlySize.progressRing)
    }
}

extension Double {
    var clampedToUnitInterval: Double { min(max(self, 0), 1) }
}
