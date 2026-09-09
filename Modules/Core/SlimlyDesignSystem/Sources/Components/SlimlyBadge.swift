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

/// Знак тарифа: круг с маркой продукта.
///
/// Марка не переводится и набирается тем же разряженным капсом, что и ярлык
/// сборки: «PRO» здесь — имя тарифа, а не слово в предложении.
public struct SlimlyProMark: View {
    private let isActive: Bool

    /// - Parameter isActive: тариф подключён. Тогда у знака появляется заливка:
    ///   в Nocturne заполненная форма читается как «включено», а пустая
    ///   рамка — как «место, где могло бы быть».
    public init(isActive: Bool) {
        self.isActive = isActive
    }

    public var body: some View {
        Text(verbatim: "PRO")
            .font(.system(size: 10, weight: .medium))
            .tracking(0.8)
            .foregroundStyle(isActive ? SlimlyColor.accent100 : SlimlyColor.accent200)
            .frame(width: 38, height: 38)
            .background(isActive ? SlimlyColor.accentTint(14) : .clear, in: Circle())
            .overlay {
                Circle().strokeBorder(
                    isActive ? SlimlyColor.accent500 : SlimlyColor.accent600,
                    lineWidth: 1
                )
            }
    }
}

/// Нажимаемая пилюля с обещанием тарифа: «PRO · БЕЗ ЛИМИТА».
///
/// Стоит там, где предел уже виден, — рядом со счётчиком выбранного. Поэтому
/// сама себя не объясняет: ей достаточно назвать, чего у тарифа нет.
public struct SlimlyProPill: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(SlimlyColor.accent200)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .overlay(Capsule().strokeBorder(SlimlyColor.accent600, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
