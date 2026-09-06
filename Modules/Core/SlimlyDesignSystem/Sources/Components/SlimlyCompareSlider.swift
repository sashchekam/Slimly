import SwiftUI

/// Шторка сравнения «до / после»: кадры лежат стопкой в одном окне, а
/// сколько видно верхнего, решает вертикальная линия, которую таскают
/// пальцем. Изначально линия стоит посередине.
///
/// Почему не переключатель на два положения: разница между оригиналом
/// и сжатой копией держится в мелочах — зерне неба, кромке волос, — и,
/// подменяя кадр целиком, её приходится держать в памяти. Со шторкой обе
/// стороны стоят рядом, и стык подводят прямо к спорному месту.
public struct SlimlyCompareSlider<Before: View, After: View>: View {
    /// Доля ширины, слева от которой виден кадр «до»: от 0 до 1.
    @Binding
    private var position: Double

    private let before: Before
    private let after: After

    /// Полоса захвата вокруг линии. Уже 44 пунктов её не поймать пальцем,
    /// а шире — она отбирает прокрутку у экрана под собой: вертикальный
    /// смах над кадром уходил бы в шторку.
    private static var grabWidth: CGFloat { 44 }
    private static var knobSize: CGFloat { 34 }
    private static var lineWidth: CGFloat { 2 }
    /// Своя система координат: жест висит на самой линии, а доля считается
    /// от левого края окна — под пальцем линия уезжает вместе с жестом.
    private static var space: String { "slimly.compare" }

    public init(
        position: Binding<Double>,
        @ViewBuilder before: () -> Before,
        @ViewBuilder after: () -> After
    ) {
        _position = position
        self.before = before()
        self.after = after()
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let x = size.width * clamped

            ZStack(alignment: .leading) {
                side(after, in: size)

                side(before, in: size)
                    // Маска, а не рамка по ширине: кадр должен остаться
                    // на своём месте и уйти под линию, а не сжаться
                    // в оставшуюся полосу.
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: x)
                    }

                divider(height: size.height)
                    .offset(x: x - Self.grabWidth / 2)
                    .gesture(drag(width: size.width))
            }
            .contentShape(Rectangle())
            // Линия ходит и по нажатию: тащить её через весь кадр ради
            // дальнего края — работа, а расширить полосу захвата на всё
            // окно нельзя — экран перестанет прокручиваться.
            .onTapGesture { point in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    position = fraction(point.x, width: size.width)
                }
            }
            .coordinateSpace(.named(Self.space))
        }
        .accessibilityElement()
        .accessibilityLabel(Text(L10n.Accessibility.compare))
        .accessibilityValue(Text(verbatim: "\(Int((clamped * 100).rounded()))%"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: position = min(clamped + 0.1, 1)
            case .decrement: position = max(clamped - 0.1, 0)
            default: break
            }
        }
    }

    private var clamped: Double { min(max(position, 0), 1) }

    /// Обе стороны меряются окном, а не собой: `scaledToFill` оставляет
    /// кадру размер больше окна, и маска шторки считалась бы от краёв
    /// кадра — линия разъезжалась бы с картинкой под ней.
    private func side(_ content: some View, in size: CGSize) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .clipped()
    }

    private func divider(height: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(SlimlyColor.neutral100)
                .frame(width: Self.lineWidth, height: height)
                // На светлом кадре белая линия растворяется, и шторка
                // перестаёт читаться как край.
                .shadow(color: .black.opacity(0.45), radius: 4)

            knob
        }
        .frame(width: Self.grabWidth, height: height)
        .contentShape(Rectangle())
    }

    private var knob: some View {
        // Стрелки врозь, а не встык: сдвинутые вплотную «‹›» читаются
        // как «свернуть», а не как «тяни в обе стороны».
        HStack(spacing: 6) {
            SlimlyIcon(.chevronLeft, width: 6)
            SlimlyIcon(.chevronRight, width: 6)
        }
        .foregroundStyle(SlimlyColor.background)
        .frame(width: Self.knobSize, height: Self.knobSize)
        .background(SlimlyColor.neutral100, in: Circle())
        .shadow(color: .black.opacity(0.5), radius: 6, y: 2)
    }

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
            .onChanged { drag in
                position = fraction(drag.location.x, width: width)
            }
    }

    private func fraction(_ x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0.5 }
        return min(max(Double(x / width), 0), 1)
    }
}
