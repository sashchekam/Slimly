import SwiftUI

/// Оживший знак: акцент обходит четыре квадрата против часовой стрелки
/// и на ходу вытягивается вдоль движения.
///
/// Кадры взяты из макета (`squeeze-splash.json`, 60 fps): перелёт на соседний
/// угол идёт кривой (0.55, 0, 0.2, 1), а растяжение 128/78 % приходится ровно
/// на середину перелёта — квадрат разгоняется и «долетает», а не тормозит
/// рывком. В отличие от макета круг здесь один: там знак крутится бесконечно,
/// здесь после круга открывается приложение. Поэтому паузы между перелётами
/// укорочены, а в конце верхний контур загорается белым — знак складывается
/// в ту же композицию, что на иконке.
///
/// В анимации все четыре контура приглушённые: белый под летящим акцентом
/// давал бы второе яркое пятно и спорил с ним за внимание.
public struct SlimlyLogoMarkAnimation: View {
    /// Тайминги круга. Собраны в одном месте: длительность заставки —
    /// это ровно их сумма, и подбирать её приходится целиком.
    private enum Timing {
        /// Пауза перед первым перелётом — знак успевает проявиться.
        static let leadIn: TimeInterval = 0.36
        static let hop: TimeInterval = 0.32
        static let gap: TimeInterval = 0.04
        static let settle: TimeInterval = 0.22
        /// Сколько знак стоит, если система просит меньше движения.
        static let still: TimeInterval = 0.7
    }

    /// Растяжение вдоль оси перелёта на его середине.
    private static let stretch: CGFloat = 1.28
    private static let squeeze: CGFloat = 0.78

    private let size: CGFloat
    private let onLanding: () -> Void
    private let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Номер угла, на котором стоит акцент. Растёт до четырёх, а не сбрасывается
    /// в ноль: иначе последний перелёт SwiftUI отыграл бы задом наперёд.
    @State
    private var corner = 0
    @State
    private var stretch = CGSize(width: 1, height: 1)
    @State
    private var isSettled = false

    public init(
        size: CGFloat,
        onLanding: @escaping () -> Void = {},
        onFinish: @escaping () -> Void = {}
    ) {
        self.size = size
        self.onLanding = onLanding
        self.onFinish = onFinish
    }

    public var body: some View {
        let scale = size / SlimlyMarkGrid.box
        let line = SlimlyMarkGrid.lineWidth(for: size)
        let side = SlimlyMarkGrid.cell * scale
        let accentSide = SlimlyMarkGrid.accentCell * scale
        let point = SlimlyMarkGrid.corners[corner % SlimlyMarkGrid.corners.count]

        ZStack {
            ForEach(SlimlyMarkGrid.corners.indices, id: \.self) { index in
                let corner = SlimlyMarkGrid.corners[index]

                RoundedRectangle(cornerRadius: SlimlyMarkGrid.corner * scale)
                    .stroke(outlineColor(at: index), lineWidth: line)
                    .frame(width: side, height: side)
                    .offset(x: corner.x * scale, y: corner.y * scale)
            }

            RoundedRectangle(cornerRadius: SlimlyMarkGrid.accentCorner * scale)
                .fill(SlimlyColor.accent)
                .frame(width: accentSide, height: accentSide)
                .scaleEffect(stretch)
                .offset(x: point.x * scale, y: point.y * scale)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(45))
        .task { await run() }
    }

    private func outlineColor(at index: Int) -> Color {
        isSettled && index == SlimlyMarkGrid.litCorner ? SlimlyColor.text : SlimlyColor.markMuted
    }

    @MainActor
    private func run() async {
        guard !reduceMotion else {
            isSettled = true
            try? await Task.sleep(for: .seconds(Timing.still))
            onFinish()
            return
        }

        try? await Task.sleep(for: .seconds(Timing.leadIn))

        for step in 1...SlimlyMarkGrid.corners.count {
            let half = Animation.timingCurve(0.55, 0, 0.2, 1, duration: Timing.hop / 2)
            // Перелёты чередуют оси, поэтому растяжение — то по ширине,
            // то по высоте: тянет всегда вдоль движения.
            let peak = step.isMultiple(of: 2)
                ? CGSize(width: Self.squeeze, height: Self.stretch)
                : CGSize(width: Self.stretch, height: Self.squeeze)

            withAnimation(.timingCurve(0.55, 0, 0.2, 1, duration: Timing.hop)) { corner = step }
            withAnimation(half) { stretch = peak }
            try? await Task.sleep(for: .seconds(Timing.hop / 2))

            withAnimation(half) { stretch = CGSize(width: 1, height: 1) }
            try? await Task.sleep(for: .seconds(Timing.hop / 2))

            onLanding()
            try? await Task.sleep(for: .seconds(Timing.gap))
        }

        withAnimation(.easeOut(duration: Timing.settle)) { isSettled = true }
        try? await Task.sleep(for: .seconds(Timing.settle))
        onFinish()
    }
}
