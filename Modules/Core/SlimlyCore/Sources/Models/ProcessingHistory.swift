import Foundation

/// Глубина среза статистики.
///
/// Три положения, а не свободный выбор дат: у приложения, которым
/// пользуются набегами, «последний месяц» и «всё время» — разные истории,
/// а календарь между ними ничего не уточняет.
public enum StatsRange: String, CaseIterable, Sendable, Hashable, Identifiable {
    case month
    case quarter
    case allTime

    public var id: String { rawValue }

    /// Глубина в днях. `nil` — у «всего времени» начало не отсчитывается
    /// назад, а берётся из первой записи журнала.
    public var days: Int? {
        switch self {
        case .month: 30
        case .quarter: 90
        case .allTime: nil
        }
    }

    public var title: String {
        switch self {
        case .month: "30 дней"
        case .quarter: "90 дней"
        case .allTime: "Всё время"
        }
    }

    /// Хвост подписи периода: «… · 30 дней», «… · всё время».
    public var caption: String {
        self == .allTime ? "всё время" : title
    }
}

/// Журнал сделанного — то, из чего собирается статистика по инструментам.
///
/// Лежит рядом с общей суммой, а не вместо неё: сумма считается с первого
/// запуска и не должна меняться от того, что журнал подрезали по краю.
public struct ProcessingHistory: Sendable, Hashable, Codable {
    /// Сколько записей храним. Запись — это один запуск обработки, а не файл,
    /// поэтому тысячи хватает надолго. Предел нужен потому, что журнал
    /// лежит в пользовательских настройках целиком, одним значением.
    public static let limit = 1000

    /// От старых к свежим — в этом же порядке их читает искра.
    public private(set) var records: [ProcessingRecord]

    public init(records: [ProcessingRecord] = []) {
        self.records = records
    }

    public static let empty = ProcessingHistory()

    public var isEmpty: Bool { records.isEmpty }

    /// Лишнее срезается с головы: свежие записи нужнее старых, а «всё время»
    /// после подрезки честно начинается с первой уцелевшей.
    public func appending(_ record: ProcessingRecord) -> ProcessingHistory {
        ProcessingHistory(records: Array((records + [record]).suffix(Self.limit)))
    }

    public func digest(for range: StatsRange, now: Date = .now) -> ProcessingDigest {
        ProcessingDigest(records: records, range: range, now: now)
    }
}
