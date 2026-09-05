import SwiftUI

/// Горизонтальная полоса прогресса.
public struct SlimlyProgressBar: View {
    /// Толстые полосы-итоги заливаются градиентом рампы, тонкие строчные —
    /// сплошным акцентом: на трёх пунктах высоты градиент всё равно не читается.
    /// Приглушённая — для полосок в ряду, где акцент занят ведущим показателем.
    public enum Fill: Sendable { case gradient, solid, muted }

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
        case .muted:
            AnyShapeStyle(SlimlyColor.neutral700)
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

/// Бесконечный индикатор загрузки: разомкнутое кольцо, у которого хвост
/// растворяется в фоне, плюс мягкое свечение под ним. Системный `ProgressView`
/// в Nocturne выглядит чужим — он берёт толщину и цвет от платформы,
/// а не от токенов.
public struct SlimlySpinner: View {
    private let size: CGFloat
    private let lineWidth: CGFloat

    @State
    private var isSpinning = false

    /// Толщина по умолчанию — десятая часть диаметра: так кольцо весит
    /// одинаково и на 24 пунктах в плеере, и на 60 в пустом экране.
    public init(size: CGFloat = 30, lineWidth: CGFloat? = nil) {
        self.size = size
        self.lineWidth = lineWidth ?? size / 10
    }

    public var body: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                // Шов градиента уводим в разрыв кольца (он сверху): иначе
                // на дуге виден скачок от тёмного хвоста к светлой голове.
                AngularGradient(
                    gradient: Gradient(colors: [SlimlyColor.accent200, SlimlyColor.accent700]),
                    center: .center,
                    angle: .degrees(-90)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .shadow(color: SlimlyColor.accent.opacity(0.35), radius: size / 4)
            .onAppear {
                // Анимация ставится в onAppear, а не в инициализаторе состояния:
                // иначе при повторном показе вью вращение не перезапускается.
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
            .accessibilityLabel(Text(L10n.Accessibility.loading))
    }
}
