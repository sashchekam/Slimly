import SwiftUI

/// Типографика Nocturne.
///
/// Система построена на Inter; файла шрифта в проекте нет, поэтому берём
/// системный гротеск — он ближе к Inter по метрикам, чем `.rounded`.
/// Иерархия здесь держится на размере и воздухе, а не на жирности:
/// заголовки не тяжелее `.medium`.
public extension Font {
    // Заголовки экранов
    static let slimlyLargeTitle = Font.system(size: 33, weight: .medium)
    static let slimlyTitle = Font.system(size: 27, weight: .medium)

    // Цифры-показатели
    static let slimlyStatXL = Font.system(size: 38, weight: .medium)
    static let slimlyStatL = Font.system(size: 33, weight: .medium)
    static let slimlyStatM = Font.system(size: 31, weight: .medium)
    static let slimlyStatS = Font.system(size: 23, weight: .medium)
    static let slimlyStatRing = Font.system(size: 30, weight: .medium)
    /// Зачёркнутый размер «до» рядом со стрелкой.
    static let slimlyStatStruck = Font.system(size: 20, weight: .regular)

    // Текст
    static let slimlySectionTitle = Font.system(size: 14.5, weight: .medium)
    static let slimlyRowTitle = Font.system(size: 13.5, weight: .regular)
    static let slimlyBody = Font.system(size: 13, weight: .regular)
    static let slimlyBodySmall = Font.system(size: 12.5, weight: .regular)
    static let slimlyCaption = Font.system(size: 11.5, weight: .regular)
    static let slimlyCaptionSmall = Font.system(size: 11, weight: .regular)
    static let slimlyMicro = Font.system(size: 10.5, weight: .regular)
    static let slimlyNano = Font.system(size: 9.5, weight: .regular)

    // Управление
    static let slimlyButton = Font.system(size: 14.5, weight: .medium)
    static let slimlyButtonSmall = Font.system(size: 12.5, weight: .medium)
    static let slimlyTabLabel = Font.system(size: 10.5, weight: .medium)
    static let slimlyPill = Font.system(size: 11, weight: .medium)
}

/// Трекинг макета в пунктах. Отрицательный — у крупных цифр и заголовков,
/// положительный — у разряженных надписей-кикеров.
public enum SlimlyTracking {
    public static let largeTitle: CGFloat = -0.7
    public static let title: CGFloat = -0.5
    public static let statXL: CGFloat = -1.2
    public static let statL: CGFloat = -1.1
    public static let statM: CGFloat = -1
    public static let statS: CGFloat = -0.6
    public static let kicker: CGFloat = 1.365
}

public extension View {
    /// Надпись-кикер над блоком: «ОСВОБОЖДЕНО ВСЕГО», «БУДЕТ», «ГОТОВО».
    func slimlyKicker() -> some View {
        font(.slimlyMicro)
            .tracking(SlimlyTracking.kicker)
            .textCase(.uppercase)
            .foregroundStyle(SlimlyColor.neutral500)
    }
}
