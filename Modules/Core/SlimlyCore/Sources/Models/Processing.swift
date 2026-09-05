import Foundation

/// Что именно делаем с файлами.
///
/// Все инструменты идут одним путём «выбор → настройки → обработка → итог»,
/// и различаются как раз этим: от вида работы зависят и тексты шагов,
/// и то, как результат ложится в статистику.
public enum ProcessingKind: String, Sendable, Hashable, Codable, CaseIterable {
    case compression
    case conversion
    case audioExtraction
    case scan

    /// Как работа называется в отчёте о сделанном.
    ///
    /// Каталог инструментов сюда не годится: там пять карточек, а конвертация
    /// фото и видео — одна и та же работа, и в статистике они складываются.
    public var title: String {
        switch self {
        case .compression: L10n.Kind.compression
        case .conversion: L10n.Kind.conversion
        case .audioExtraction: L10n.Kind.audioExtraction
        case .scan: L10n.Kind.scan
        }
    }

    /// Имя для тесных мест — легенды под полосой долей, где полное
    /// не помещается.
    public var shortTitle: String {
        switch self {
        case .compression: L10n.KindShort.compression
        case .conversion: L10n.KindShort.conversion
        case .audioExtraction: L10n.KindShort.audioExtraction
        case .scan: L10n.KindShort.scan
        }
    }

    /// Что считает счётчик операций у этого вида работы: сжатие и конвертация
    /// работают с файлами, звук достаётся из видео, а скан считается
    /// документами, а не страницами.
    public var unit: CountFormatter.Noun {
        switch self {
        case .compression, .conversion: .file
        case .audioExtraction: .video
        case .scan: .scan
        }
    }
}

// MARK: - Форматы результата

/// Формат изображения, который система умеет записать.
///
/// WebP здесь нет намеренно: ImageIO на iOS его читает, но не пишет,
/// поэтому предлагать такой пункт было бы обманом.
public enum ImageFormat: String, Sendable, Hashable, CaseIterable {
    case jpeg
    case heic
    case png

    public var displayName: String {
        switch self {
        case .jpeg: "JPEG"
        case .heic: "HEIC"
        case .png: "PNG"
        }
    }

    public var fileExtension: String {
        switch self {
        case .jpeg: "jpg"
        case .heic: "heic"
        case .png: "png"
        }
    }

    /// У PNG качество не регулируется — он без потерь.
    public var isLossy: Bool { self != .png }
}

public enum VideoContainer: String, Sendable, Hashable {
    case mp4
    case mov

    public var displayName: String { rawValue.uppercased() }
    public var fileExtension: String { rawValue }
}

public enum VideoCodec: String, Sendable, Hashable {
    case h264
    case hevc

    public var displayName: String {
        switch self {
        case .h264: "H.264"
        case .hevc: "HEVC"
        }
    }
}

/// Формат звуковой дорожки.
public enum AudioFormat: Sendable, Hashable {
    /// AAC в контейнере M4A — родной для iOS.
    case aac(kilobits: Int)
    /// WAV без потерь. MP3 не предлагаем: кодировщика MP3 в iOS нет.
    case linearPCM

    public var displayName: String {
        switch self {
        case let .aac(kilobits): L10n.AudioFormat.aac(kilobits)
        case .linearPCM: L10n.AudioFormat.wav
        }
    }

    public var fileExtension: String {
        switch self {
        case .aac: "m4a"
        case .linearPCM: "wav"
        }
    }

    /// Байт в секунду — по нему считается оценка веса дорожки.
    /// Для WAV это 44,1 кГц × 16 бит × 2 канала.
    public var bytesPerSecond: Double {
        switch self {
        case let .aac(kilobits): Double(kilobits) * 1000 / 8
        case .linearPCM: 44_100 * 2 * 2
        }
    }
}

/// Во что превращаем файл. Отсюда обработчик берёт настройки кодировщика,
/// а интерфейс — подпись формата.
public enum ProcessingTarget: Sendable, Hashable {
    case image(ImageFormat)
    case video(container: VideoContainer, codec: VideoCodec)
    case audio(AudioFormat)
    /// PDF из страниц скана. Режим — часть цели, а не отдельная настройка:
    /// от него зависит то, как выглядит собранная страница.
    case document(ScanMode)

    public var displayName: String {
        switch self {
        case let .image(format): format.displayName
        case let .video(container, codec): "\(container.displayName) · \(codec.displayName)"
        case let .audio(format): format.displayName
        case let .document(mode): "PDF · \(mode.displayName)"
        }
    }
}

/// Формат результата: «JPEG», «MP4 · H.264», «M4A · 128 кбит».
///
/// Коэффициент — оценка веса относительно оригинала; у PNG он больше единицы,
/// и это честно: конвертация не всегда облегчает файл. Там, где вес не
/// показывают и не считают, оценки нет — коэффициент остаётся единицей.
public struct MediaFormat: Sendable, Hashable, Identifiable {
    public let target: ProcessingTarget
    public let ratio: Double

    public init(target: ProcessingTarget, ratio: Double = 1) {
        self.target = target
        self.ratio = ratio
    }

    public var id: String { target.displayName }

    /// Короткое имя без уточнения кодека — для строк результата.
    public var shortName: String {
        id.components(separatedBy: " · ").first ?? id
    }
}

// MARK: - Степень сжатия

/// Пресет сжатия. Коэффициент — доля исходного веса, которая останется.
public enum CompressionPreset: String, CaseIterable, Sendable, Hashable, Identifiable {
    case light
    case medium
    case maximum

    public var id: String { rawValue }

    public var ratio: Double {
        switch self {
        case .light: 0.68
        case .medium: 0.42
        case .maximum: 0.24
        }
    }

    public var title: String {
        switch self {
        case .light: L10n.Quality.light
        case .medium: L10n.Quality.medium
        case .maximum: L10n.Quality.maximum
        }
    }

    public var summary: String {
        switch self {
        case .light: L10n.QualitySummary.light
        case .medium: L10n.QualitySummary.medium
        case .maximum: L10n.QualitySummary.maximum
        }
    }
}

/// Положение ползунка степени сжатия.
///
/// Пресеты — это засечки на непрерывной шкале, а не три отдельных режима:
/// между ними коэффициент интерполируется, поэтому промежуточное положение
/// ползунка тоже имеет смысл, а не «прилипает» к ближайшему пресету.
public struct CompressionLevel: Sendable, Hashable {
    public var value: Double

    public init(value: Double = 0.5) {
        self.value = min(max(value, 0), 1)
    }

    public static let `default` = CompressionLevel()

    public var ratio: Double {
        let presets = CompressionPreset.allCases
        let scaled = value * Double(presets.count - 1)
        let index = min(Int(scaled), presets.count - 2)
        let fraction = scaled - Double(index)
        let from = presets[index].ratio
        return from + fraction * (presets[index + 1].ratio - from)
    }

    /// Пресет, подпись которого подсвечена над ползунком.
    public var nearestPreset: CompressionPreset {
        let presets = CompressionPreset.allCases
        let index = Int((value * Double(presets.count - 1)).rounded())
        return presets[min(max(index, 0), presets.count - 1)]
    }

    public static func at(_ preset: CompressionPreset) -> CompressionLevel {
        let presets = CompressionPreset.allCases
        let index = presets.firstIndex(of: preset) ?? 0
        return CompressionLevel(value: Double(index) / Double(presets.count - 1))
    }
}

// MARK: - Задание

/// Работа, которую нужно проделать над файлами.
///
/// Настройки кодировщика выводятся отсюда, а не приходят числом «доля веса»:
/// коэффициент — это оценка для интерфейса, а обработке нужно знать формат,
/// кодек и качество.
public enum ProcessingOperation: Sendable, Hashable {
    /// Сжатие без смены формата — исходный контейнер сохраняется.
    case compress(CompressionLevel)
    case convert(MediaFormat)
    case extractAudio(MediaFormat)
    /// Сборка PDF из страниц. Границы листа идут вместе с форматом: их
    /// либо нашла автоматика, либо поправил человек, и обработка не должна
    /// гадать, чьи они, — она просто берёт то, что ей дали.
    case scan(MediaFormat, bounds: ScanBounds)

    public var kind: ProcessingKind {
        switch self {
        case .compress: .compression
        case .convert: .conversion
        case .extractAudio: .audioExtraction
        case .scan: .scan
        }
    }

    /// У сжатия формат не меняется, поэтому пары «из → в» нет.
    public var targetFormat: MediaFormat? {
        switch self {
        case .compress: nil
        case let .convert(format), let .extractAudio(format): format
        case let .scan(format, _): format
        }
    }

    /// Доля исходного веса, которая останется, — оценка до обработки.
    public var estimatedRatio: Double {
        switch self {
        case let .compress(level): level.ratio
        case let .convert(format), let .extractAudio(format): format.ratio
        case let .scan(format, _): format.ratio
        }
    }
}

/// Задание на обработку — всё, что нужно знать сервису и экранам после него.
public struct ProcessingRequest: Sendable, Hashable {
    public let items: [MediaItem]
    public let operation: ProcessingOperation
    /// Исходный формат: «HEIC», «MOV · HEVC». Показываем в паре «из → в».
    /// У сжатия формат не меняется, поэтому пара не нужна и строка пуста.
    public let sourceFormat: String

    public init(items: [MediaItem], operation: ProcessingOperation, sourceFormat: String = "") {
        self.items = items
        self.operation = operation
        self.sourceFormat = sourceFormat
    }

    public var kind: ProcessingKind { operation.kind }

    public var ratio: Double { operation.estimatedRatio }

    public var targetFormat: MediaFormat? { operation.targetFormat }

    public var originalByteCount: Int64 { items.totalByteCount }

    /// Вес «после» до обработки — оценка, поэтому в интерфейсе всегда
    /// подписан как приблизительный.
    public var estimatedByteCount: Int64 {
        items.reduce(0) { $0 + estimatedByteCount(for: $1) }
    }

    /// Вес дорожки считаем по битрейту и длительности, а не долей от видео:
    /// час разговора и час съёмки 4K дают одинаковый звук и разные видео.
    public func estimatedByteCount(for item: MediaItem) -> Int64 {
        if
            case let .extractAudio(format) = operation,
            case let .audio(audio) = format.target,
            let duration = item.duration
        {
            return Int64(audio.bytesPerSecond * duration.seconds)
        }
        // Считаем от того файла, который реально пойдёт в кодировщик:
        // у обрезанного видео это рендер правок, а не исходник с камеры.
        return Int64(Double(item.sourceByteCount) * ratio)
    }

    /// «−58%». У конвертации может получиться и прибавка — знак берём из числа.
    public var deltaPercent: Int {
        guard originalByteCount > 0 else { return 0 }
        let remaining = Double(estimatedByteCount) / Double(originalByteCount)
        return Int(((1 - remaining) * 100).rounded())
    }
}

// MARK: - Результат

public struct ProcessingResult: Sendable, Hashable, Identifiable {
    public let item: MediaItem
    public let outputByteCount: Int64
    /// Имя готового файла — у конвертации и звука оно отличается от исходного.
    public let outputName: String
    /// Готовый файл в кэше приложения. Пока результат не сохранён, это
    /// единственное место, где он есть; после сохранения — копия, по которой
    /// показываем «после» в сравнении.
    public let outputURL: URL?
    /// Куда результат уедет, когда его сохранят: медиатека или папка
    /// приложения в «Файлах».
    public let destination: OutputDestination

    public init(
        item: MediaItem,
        outputByteCount: Int64,
        outputName: String,
        outputURL: URL? = nil,
        destination: OutputDestination = .photoLibrary
    ) {
        self.item = item
        self.outputByteCount = outputByteCount
        self.outputName = outputName
        self.outputURL = outputURL
        self.destination = destination
    }

    public var id: String { item.id }

    /// Тот же результат, но по новому адресу: уехав в «Файлы», файл меняет
    /// место, и ссылка из кэша после этого никуда не ведёт.
    public func stored(at url: URL) -> ProcessingResult {
        ProcessingResult(
            item: item,
            outputByteCount: outputByteCount,
            outputName: outputName,
            outputURL: url,
            destination: destination
        )
    }

    public var savedByteCount: Int64 { item.byteCount - outputByteCount }

    /// Доля, на которую файл похудел: 0.64 — это «−64%».
    public var reduction: Double {
        guard item.byteCount > 0 else { return 0 }
        return 1 - Double(outputByteCount) / Double(item.byteCount)
    }
}

/// Куда лёг готовый файл.
public enum OutputDestination: Sendable, Hashable {
    case photoLibrary
    /// Папка приложения в «Файлах» — туда, чему в медиатеке не место.
    case files
}

/// Файл, который обработать не удалось.
///
/// Отказ по одному файлу не отменяет остальные: медиатека умеет отдать
/// битый ассет или файл из iCloud, которого нет на устройстве.
public struct ProcessingFailure: Sendable, Hashable, Identifiable {
    public let item: MediaItem
    public let message: String

    public init(item: MediaItem, message: String) {
        self.item = item
        self.message = message
    }

    public var id: String { item.id }
}

public extension Sequence<ProcessingResult> {
    var originalByteCount: Int64 { reduce(0) { $0 + $1.item.byteCount } }
    var outputByteCount: Int64 { reduce(0) { $0 + $1.outputByteCount } }
    var savedByteCount: Int64 { reduce(0) { $0 + $1.savedByteCount } }
}

// MARK: - Прогресс

public struct ItemProgress: Sendable, Hashable, Identifiable {
    public let id: String
    public let fraction: Double

    public init(id: String, fraction: Double) {
        self.id = id
        self.fraction = fraction
    }
}

public struct ProcessingProgress: Sendable, Hashable {
    public let overall: Double
    public let items: [ItemProgress]
    /// `nil`, пока оценивать не по чему: первые доли секунды прогноз
    /// был бы выдумкой.
    public let estimatedRemaining: Duration?

    public init(overall: Double, items: [ItemProgress], estimatedRemaining: Duration?) {
        self.overall = overall
        self.items = items
        self.estimatedRemaining = estimatedRemaining
    }

    public static func idle(_ items: [MediaItem]) -> ProcessingProgress {
        ProcessingProgress(
            overall: 0,
            items: items.map { ItemProgress(id: $0.id, fraction: 0) },
            estimatedRemaining: nil
        )
    }

    public func fraction(for item: MediaItem) -> Double {
        items.first { $0.id == item.id }?.fraction ?? 0
    }
}

// MARK: - Итог

/// Чем закончилась обработка. Задание носим с собой: экран итога говорит
/// о результате по-разному в зависимости от того, что именно делали.
public struct ProcessingOutcome: Sendable, Hashable {
    public let request: ProcessingRequest
    public let results: [ProcessingResult]
    public let failures: [ProcessingFailure]

    public init(
        request: ProcessingRequest,
        results: [ProcessingResult],
        failures: [ProcessingFailure] = []
    ) {
        self.request = request
        self.results = results
        self.failures = failures
    }

    public var kind: ProcessingKind { request.kind }

    /// Ни одного готового файла — итог показываем как неудачу.
    public var isEmpty: Bool { results.isEmpty }
}

public enum ProcessingEvent: Sendable {
    case progress(ProcessingProgress)
    case finished(ProcessingOutcome)
}
