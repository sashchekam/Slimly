import Foundation
import SlimlyCore

/// Тексты общих шагов флоу.
///
/// Инструменты идут одной дорогой и различаются только тем, что делают
/// с файлами, — поэтому подписи шагов выводятся из ``ProcessingKind``,
/// а не переписываются в каждой фиче.
public enum FlowCopy {
    /// Подпись под процентом на экране обработки.
    public static func runWord(_ kind: ProcessingKind) -> String {
        switch kind {
        case .compression: "сжимаем"
        case .conversion: "конвертируем"
        case .audioExtraction: "извлекаем"
        case .scan: "сканируем"
        }
    }

    /// Кикер над итогом.
    public static func doneKicker(_ kind: ProcessingKind) -> String {
        switch kind {
        case .compression: "сжатие завершено"
        case .conversion: "формат изменён"
        case .audioExtraction: "звук извлечён"
        case .scan: "скан собран"
        }
    }

    /// Строка под крупной цифрой итога.
    public static func summary(_ outcome: ProcessingOutcome) -> String {
        let results = outcome.results
        let count = results.count
        let target = outcome.request.targetFormat?.shortName ?? ""

        switch outcome.kind {
        case .compression:
            // Уже плотно упакованный файл после пережатия может даже
            // потяжелеть. Писать «освободили −0,2 МБ» нельзя: это не итог,
            // а издевательство.
            guard results.savedByteCount > 0 else {
                return "Файлы и так были плотными — вес почти не изменился · \(CountFormatter.string(count, .file))"
            }
            return [
                "Освободили \(FileSizeFormatter.string(bytes: results.savedByteCount))",
                CountFormatter.string(count, .file),
                "оригиналы на месте",
            ].joined(separator: " · ")

        case .conversion:
            return "\(CountFormatter.string(count, .file)) пересобрано в \(target) · оригиналы на месте"

        case .audioExtraction:
            let total = FileSizeFormatter.string(bytes: results.outputByteCount)
            return "\(CountFormatter.string(count, .track)) по \(target) · всего \(total) · видео не изменялось"

        case .scan:
            return "\(CountFormatter.string(count, .page)) в одном \(target) · оригиналы на месте"
        }
    }

    /// Показывать ли предложение удалить оригиналы.
    ///
    /// Только там, где оригинал действительно стал лишним: после извлечения
    /// звука видео нужно как было, а скан оригиналы вообще не заменяет.
    public static func offersDeletingOriginals(_ kind: ProcessingKind) -> Bool {
        switch kind {
        case .compression, .conversion: true
        case .audioExtraction, .scan: false
        }
    }

    /// Сравнение «до / после» имеет смысл только у сжатия: там меняется
    /// картинка, а не контейнер.
    public static func allowsComparison(_ kind: ProcessingKind) -> Bool {
        kind == .compression
    }
}
