import SwiftUI

/// Искра: ряд столбиков одинаковой ширины, высота — доля от самого большого.
///
/// Осей и подписей нет намеренно. Искра отвечает на «ровно или рывками»,
/// а на «сколько именно» отвечает цифра рядом — две шкалы на одном месте
/// спорили бы друг с другом.
public struct SlimlySparkline: View {
    /// Чем красить столбики. Акцент достаётся ведущему показателю: если
    /// подсветить все, подсветка перестаёт что-либо значить.
    public enum Tint: Sendable { case accent, neutral }

    private let values: [Double]
    private let tint: Tint
    private let height: CGFloat

    public init(values: [Double], tint: Tint = .neutral, height: CGFloat = 34) {
        self.values = values
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(isLast: index == values.count - 1))
                    // Пустой отрезок всё равно рисует полоску в два пункта:
                    // без неё в ряду появляется дыра, и он читается как
                    // обрыв данных, а не как ноль.
                    .frame(maxWidth: .infinity)
                    .frame(height: max(2, height * value.clampedToUnitInterval))
            }
        }
        .frame(height: height, alignment: .bottom)
        // Рисунок декоративный: то же самое сказано числами в той же карточке.
        .accessibilityHidden(true)
    }

    /// Свежий столбик светлее остальных — он и есть «сейчас».
    private func color(isLast: Bool) -> Color {
        switch (tint, isLast) {
        case (.accent, true): SlimlyColor.accent400
        case (.accent, false): SlimlyColor.accent700
        case (.neutral, true): SlimlyColor.neutral500
        case (.neutral, false): SlimlyColor.neutral800
        }
    }
}

/// Полоса долей: несколько кусков разного цвета в одной капсуле.
///
/// Заменяет круговую диаграмму: доли здесь читают по длине, а не по углу,
/// и полоса ложится в ширину карточки, ничего не занимая по высоте.
public struct SlimlyShareBar: View {
    public struct Segment: Identifiable, Sendable {
        public let id: String
        /// Доля от целого, 0…1.
        public let share: Double
        public let color: Color

        public init(id: String, share: Double, color: Color) {
            self.id = id
            self.share = share
            self.color = color
        }
    }

    private let segments: [Segment]
    private let height: CGFloat

    public init(segments: [Segment], height: CGFloat = 8) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    segment.color
                        .frame(width: proxy.size.width * segment.share.clampedToUnitInterval)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
        .background(SlimlyColor.neutral900)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}
