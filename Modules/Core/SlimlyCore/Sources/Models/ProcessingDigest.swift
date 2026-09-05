import Foundation

private let secondsInDay: TimeInterval = 86_400

/// Что сделал один инструмент за выбранный срез.
///
/// Числа сырые, без подписей: одно и то же количество страниц экран
/// показывает и цифрой, и внутри фразы, и склонять их дважды по-разному
/// не стоит — этим занимается тот, кто рисует.
public struct ToolStats: Sendable, Hashable, Identifiable {
    public let kind: ProcessingKind
    /// Операций: файлов, а у скана — собранных документов.
    public let count: Int
    public let originalByteCount: Int64
    public let outputByteCount: Int64
    public let photoCount: Int
    public let videoCount: Int
    public let pageCount: Int
    /// Суммарная длительность исходников — у извлечения звука.
    public let seconds: Double
    /// Пары «из → в» по убыванию частоты: «HEIC → JPEG».
    public let formatPairs: [String]
    /// Форматы результата по убыванию частоты: «M4A», «PDF».
    public let formats: [String]
    /// Высоты столбиков искры, 0…1. Длина — ``ProcessingDigest/sparkBarCount``.
    public let spark: [Double]

    public var id: ProcessingKind { kind }

    public var isEmpty: Bool { count == 0 }

    public var savedByteCount: Int64 { originalByteCount - outputByteCount }

    /// Средний выигрыш по весу: 0.58 — это «−58%». Считается по общему весу,
    /// а не как среднее из процентов: иначе один крошечный файл весил бы
    /// в среднем столько же, сколько часовое видео.
    public var reduction: Double {
        guard originalByteCount > 0 else { return 0 }
        return 1 - Double(outputByteCount) / Double(originalByteCount)
    }

    /// Страниц на документ — округляем вверх: «в среднем 3,5 страницы»
    /// звучит точнее, чем есть.
    public var pagesPerDocument: Int {
        guard count > 0 else { return 0 }
        return Int((Double(pageCount) / Double(count)).rounded())
    }

    init(kind: ProcessingKind, records: [ProcessingRecord], interval: DateInterval?) {
        self.kind = kind
        count = records.reduce(0) { $0 + $1.count }
        originalByteCount = records.reduce(0) { $0 + $1.originalByteCount }
        outputByteCount = records.reduce(0) { $0 + $1.outputByteCount }
        photoCount = records.reduce(0) { $0 + $1.photoCount }
        videoCount = records.reduce(0) { $0 + $1.videoCount }
        pageCount = records.reduce(0) { $0 + $1.pageCount }
        seconds = records.reduce(0) { $0 + $1.seconds }
        formatPairs = Self.ranked(records.map(\.formatPair))
        formats = Self.ranked(records.map(\.targetFormat))
        spark = Self.sparkBars(records, in: interval)
    }

    /// Значения по убыванию частоты. Одинаково частые идут по алфавиту:
    /// «чаще всего» не должно меняться местами от перезапуска к перезапуску.
    private static func ranked(_ values: [String]) -> [String] {
        var counts: [String: Int] = [:]
        for value in values where !value.isEmpty {
            counts[value, default: 0] += 1
        }
        return counts
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .map(\.key)
    }

    /// Столбики искры: количество операций по равным долям отрезка,
    /// поделённое на самый высокий столбик.
    private static func sparkBars(_ records: [ProcessingRecord], in interval: DateInterval?) -> [Double] {
        let bars = ProcessingDigest.sparkBarCount
        var buckets = [Double](repeating: 0, count: bars)

        guard let interval, interval.duration > 0 else { return buckets }

        for record in records {
            let offset = record.date.timeIntervalSince(interval.start) / interval.duration
            let index = min(max(Int(offset * Double(bars)), 0), bars - 1)
            buckets[index] += Double(record.count)
        }

        guard let peak = buckets.max(), peak > 0 else { return buckets }
        return buckets.map { $0 / peak }
    }
}

/// Статистика за срез: сколько работ и как они разошлись по инструментам.
public struct ProcessingDigest: Sendable, Hashable {
    /// Двенадцать столбиков искры: меньше — рисунок распадается на отдельные
    /// палки, больше — не читается на ширине карточки.
    public static let sparkBarCount = 12

    public let range: StatsRange
    /// Отрезок, за который посчитано. `nil` — у «всего времени», пока
    /// не сделано ни одной обработки: подписывать нечего.
    public let interval: DateInterval?
    /// Все виды работ в порядке ``ProcessingKind/allCases``, включая пустые:
    /// «ни разу» — тоже ответ, и ноль честнее пропущенной строки.
    public let tools: [ToolStats]

    init(records: [ProcessingRecord], range: StatsRange, now: Date) {
        // У среза с глубиной начало отсчитывается назад от «сейчас»,
        // у «всего времени» — берётся из первой записи журнала.
        let start = range.days.map { now.addingTimeInterval(-Double($0) * secondsInDay) }
            ?? records.first?.date
        let interval = start.map { DateInterval(start: min($0, now), end: now) }
        let slice = interval.map { window in records.filter { window.contains($0.date) } } ?? []

        self.range = range
        self.interval = interval
        tools = ProcessingKind.allCases.map { kind in
            ToolStats(kind: kind, records: slice.filter { $0.kind == kind }, interval: interval)
        }
    }

    public var total: Int { tools.reduce(0) { $0 + $1.count } }

    public var isEmpty: Bool { total == 0 }

    /// Доля инструмента в общем числе операций — ширина его куска полосы.
    public func share(of kind: ProcessingKind) -> Double {
        guard total > 0 else { return 0 }
        return Double(stats(for: kind).count) / Double(total)
    }

    public func stats(for kind: ProcessingKind) -> ToolStats {
        // Список собран из `allCases`, поэтому промах здесь означал бы,
        // что вид работы завели мимо перечисления.
        tools.first { $0.kind == kind } ?? ToolStats(kind: kind, records: [], interval: nil)
    }

    /// Подпись периода: «1 июня — 4 сентября · 90 дней», «с 12 января · всё время».
    public func periodText(now: Date = .now) -> String {
        guard let interval else { return L10n.Digest.empty }

        if range == .allTime {
            let start = MediaDateFormatter.day(interval.start, now: now)
            return L10n.Digest.since(start, range.caption)
        }
        let span = MediaDateFormatter.string(from: interval.start, to: interval.end, now: now)
        return "\(span) · \(range.caption)"
    }
}
