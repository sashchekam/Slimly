import Foundation

/// Ачивка. Прогресс не хранится, а считается из статистики: иначе два
/// источника правды рано или поздно разойдутся.
public struct Achievement: Sendable, Hashable, Identifiable {
    public enum Goal: Sendable, Hashable {
        case savedBytes(Int64)
        case fileCount(Int)
        case streakDays(Int)
    }

    public let id: String
    /// Короткая надпись внутри кружка: «10», «3 ГБ».
    public let glyph: String
    public let title: String
    public let subtitle: String
    /// Как о ней сообщить сразу после обработки.
    public let celebration: String
    public let goal: Goal

    public init(
        id: String,
        glyph: String,
        title: String,
        subtitle: String,
        celebration: String,
        goal: Goal
    ) {
        self.id = id
        self.glyph = glyph
        self.title = title
        self.subtitle = subtitle
        self.celebration = celebration
        self.goal = goal
    }

    public func progress(in stats: CompressionStats) -> Double {
        let fraction: Double = switch goal {
        case let .savedBytes(target):
            target > 0 ? Double(stats.savedByteCount) / Double(target) : 1
        case let .fileCount(target):
            target > 0 ? Double(stats.fileCount) / Double(target) : 1
        case let .streakDays(target):
            target > 0 ? Double(stats.streakDays) / Double(target) : 1
        }
        return min(max(fraction, 0), 1)
    }

    public func isEarned(in stats: CompressionStats) -> Bool {
        progress(in: stats) >= 1
    }

    /// Как назвать цель в строке «Ближайшая: …».
    public var goalDescription: String {
        switch goal {
        case .savedBytes: "\(subtitle) освобождено"
        case .fileCount, .streakDays: subtitle
        }
    }

    /// Сколько ещё нужно до цели, словами: «3,4 / 5 ГБ».
    public func progressText(in stats: CompressionStats) -> String {
        switch goal {
        case let .savedBytes(target):
            "\(FileSizeFormatter.string(bytes: stats.savedByteCount, unit: .gigabytes)) / \(FileSizeFormatter.string(bytes: target))"
        case let .fileCount(target):
            "\(stats.fileCount) / \(target)"
        case let .streakDays(target):
            "\(stats.streakDays) / \(target)"
        }
    }
}

public extension Achievement {
    /// Полный список. Считается вместе со статистикой, поэтому «3 из 8»
    /// в профиле — не константа, а результат подсчёта.
    static let catalogue: [Achievement] = [
        Achievement(
            id: "files-10",
            glyph: "10",
            title: "Первая десятка",
            subtitle: "10 файлов",
            celebration: "Первая десятка файлов",
            goal: .fileCount(10)
        ),
        Achievement(
            id: "saved-1gb",
            glyph: "1 ГБ",
            title: "Первый гигабайт",
            subtitle: "1 ГБ",
            celebration: "Полегчало на 1 ГБ",
            goal: .savedBytes(1 << 30)
        ),
        Achievement(
            id: "saved-3gb",
            glyph: "3 ГБ",
            title: "Полегчало",
            subtitle: "3 ГБ",
            celebration: "Полегчало на 3 ГБ",
            goal: .savedBytes(3 << 30)
        ),
        Achievement(
            id: "saved-5gb",
            glyph: "5 ГБ",
            title: "Уборка",
            subtitle: "5 ГБ",
            celebration: "Полегчало на 5 ГБ",
            goal: .savedBytes(5 << 30)
        ),
        Achievement(
            id: "files-100",
            glyph: "100",
            title: "Сотня",
            subtitle: "100 файлов",
            celebration: "Сотня файлов позади",
            goal: .fileCount(100)
        ),
        Achievement(
            id: "streak-7",
            glyph: "7",
            title: "Неделя",
            subtitle: "7 дней подряд",
            celebration: "Неделя подряд",
            goal: .streakDays(7)
        ),
        Achievement(
            id: "saved-10gb",
            glyph: "10 ГБ",
            title: "Генеральная",
            subtitle: "10 ГБ",
            celebration: "Полегчало на 10 ГБ",
            goal: .savedBytes(10 << 30)
        ),
        Achievement(
            id: "files-500",
            glyph: "500",
            title: "Полтысячи",
            subtitle: "500 файлов",
            celebration: "Полтысячи файлов",
            goal: .fileCount(500)
        ),
    ]

    static func earned(in stats: CompressionStats) -> [Achievement] {
        catalogue.filter { $0.isEarned(in: stats) }
    }

    /// Ближайшая незакрытая — та, к которой подошли ближе всего.
    static func next(in stats: CompressionStats) -> Achievement? {
        catalogue
            .filter { !$0.isEarned(in: stats) }
            .max { $0.progress(in: stats) < $1.progress(in: stats) }
    }
}
