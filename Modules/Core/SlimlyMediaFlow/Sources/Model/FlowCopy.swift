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
        case .compression: L10n.Stage.compressing
        case .conversion: L10n.Stage.converting
        case .audioExtraction: L10n.Stage.extracting
        case .scan: L10n.Stage.scanning
        }
    }

    /// Кикер над итогом.
    public static func doneKicker(_ kind: ProcessingKind) -> String {
        switch kind {
        case .compression: L10n.Stage.compressionDone
        case .conversion: L10n.Stage.conversionDone
        case .audioExtraction: L10n.Stage.audioDone
        case .scan: L10n.Stage.scanDone
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
            let files = CountFormatter.string(count, .file)
            guard results.savedByteCount > 0 else {
                return L10n.Summary.dense(files)
            }
            let saved = FileSizeFormatter.string(bytes: results.savedByteCount)
            return [
                L10n.Summary.freed(saved),
                files,
                L10n.Summary.originalsUntouched,
            ].joined(separator: " · ")

        case .conversion:
            let files = CountFormatter.string(count, .file)
            return L10n.Summary.conversion(files, target)

        case .audioExtraction:
            let total = FileSizeFormatter.string(bytes: results.outputByteCount)
            let tracks = CountFormatter.string(count, .track)
            return L10n.Summary.audio(tracks, target, total)

        case .scan:
            // Страниц столько, сколько снимков взяли, а результат один —
            // считать страницы по числу файлов итога значило бы написать
            // «1 страница» на пятистраничном документе.
            let pages = CountFormatter.string(outcome.request.items.count, .page)
            return L10n.Summary.scan(pages, target)
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

    /// Подсказка под списком готовых файлов. У сжатия смотрят пару
    /// «до / после», дорожку слушают, а остальное просто открывают —
    /// звать «сравнить» везде было бы враньём.
    public static func previewHint(_ kind: ProcessingKind) -> String {
        switch kind {
        case .compression: L10n.Hint.compression
        case .audioExtraction: L10n.Hint.audio
        case .conversion, .scan: L10n.Hint.preview
        }
    }

    /// Сравнение «до / после» имеет смысл только у сжатия: там меняется
    /// картинка, а не контейнер.
    public static func allowsComparison(_ kind: ProcessingKind) -> Bool {
        kind == .compression
    }
}
