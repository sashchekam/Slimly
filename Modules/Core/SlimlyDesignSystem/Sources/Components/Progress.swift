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

/// Бесконечный индикатор загрузки: акцентная дуга, тающая в хвосте, по тёмному
/// ободу. Системный `ProgressView` в Nocturne выглядит чужим — он берёт
/// толщину и цвет от платформы, а не от токенов.
public struct SlimlySpinner: View {
    private let size: CGFloat
    private let lineWidth: CGFloat

    @State private var isSpinning = false

    public init(size: CGFloat = 30, lineWidth: CGFloat = 3) {
        self.size = size
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(SlimlyColor.neutral900, lineWidth: lineWidth)

            Circle()
                .inset(by: lineWidth / 2)
                .trim(from: 0, to: 0.3)
                .stroke(
                    AngularGradient(
                        colors: [SlimlyColor.accent.opacity(0), SlimlyColor.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
        }
        .frame(width: size, height: size)
        .onAppear {
            // Анимация ставится в onAppear, а не в инициализаторе состояния:
            // иначе при повторном показе вью вращение не перезапускается.
            withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
        .accessibilityLabel("Загрузка")
    }
}
