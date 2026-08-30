import SwiftUI

/// Пилюля с дельтой сжатия: «−64%».
public struct SlimlyDeltaBadge: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.slimlyPill)
            .foregroundStyle(SlimlyColor.accent300)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(SlimlyColor.accent900, in: Capsule())
    }
}

/// Ярлык моноширинным капсом: «INTERNAL», «DEBUG».
///
/// Не статус и не действие — подпись к тому, что перед глазами не та сборка,
/// которая уедет в App Store. Моноширинный шрифт здесь работает как маркер
/// «служебное»: в продуктовом интерфейсе его больше нигде нет.
public struct SlimlyTagBadge: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(0.9)
            .foregroundStyle(SlimlyColor.accent300)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                SlimlyColor.accent900,
                in: RoundedRectangle(cornerRadius: SlimlyRadius.sm, style: .continuous)
            )
    }
}
