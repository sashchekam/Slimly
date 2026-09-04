import Foundation

/// Одна законченная работа: что сделали, когда и над чем.
///
/// Общей суммы в профиле хватало, пока вопрос был один — «сколько всего
/// освобождено». На вопрос «чем пользовались за последние 90 дней» сумма
/// не отвечает, поэтому рядом с ней лежит список записей с датами.
///
/// Запись пишется на всю пачку разом, а не на каждый файл: обработку
/// запускают один раз, и в отчёте это одна работа с несколькими
/// результатами, а не десять отдельных.
public struct ProcessingRecord: Sendable, Hashable, Codable {
    public let date: Date
    public let kind: ProcessingKind
    /// Сколько результатов легло в счётчик операций: файлов, а у скана —
    /// собранных документов.
    public let count: Int
    public let originalByteCount: Int64
    public let outputByteCount: Int64
    public let photoCount: Int
    public let videoCount: Int
    /// Страниц в собранном PDF — только у скана.
    public let pageCount: Int
    /// Длительность исходников в секундах — только у извлечения звука.
    /// Секунды, а не `Duration`: запись уезжает в хранилище через `Codable`.
    public let seconds: Double
    /// Формат исходников: «HEIC», «MOV». У сжатия формат не меняется,
    /// поэтому пары «из → в» нет и строка пуста.
    public let sourceFormat: String
    /// Формат результата: «JPEG», «M4A», «PDF».
    public let targetFormat: String

    /// Запись по итогу обработки. Считается по сохранённым результатам,
    /// а не по заданию: профиль показывает сделанное, и отказ по файлу
    /// в отчёт попасть не должен.
    public init(_ outcome: ProcessingOutcome, date: Date = .now) {
        let results = outcome.results

        self.date = date
        kind = outcome.kind
        count = results.count
        originalByteCount = results.originalByteCount
        outputByteCount = results.outputByteCount
        photoCount = results.filter { $0.item.kind == .photo }.count
        videoCount = results.filter { $0.item.kind == .video }.count
        // Страницы считаются по заданию, а не по результатам: из пачки
        // снимков выходит один PDF, и в результатах их уже не видно.
        pageCount = outcome.kind == .scan ? outcome.request.items.count : 0
        seconds = outcome.kind == .audioExtraction
            ? results.reduce(0) { $0 + ($1.item.duration?.seconds ?? 0) }
            : 0
        sourceFormat = outcome.request.sourceFormat
        targetFormat = outcome.request.targetFormat?.shortName ?? ""
    }

    /// «HEIC → JPEG». Пусто, если формат не менялся или система его
    /// не назвала.
    public var formatPair: String {
        guard !sourceFormat.isEmpty, !targetFormat.isEmpty else { return "" }
        return "\(sourceFormat) → \(targetFormat)"
    }
}
