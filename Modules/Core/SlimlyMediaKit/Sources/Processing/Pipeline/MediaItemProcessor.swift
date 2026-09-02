import Foundation
import SlimlyCore

/// Обработка одного файла: от оригинала из медиатеки до готового результата.
protocol ItemProcessing: Sendable {
    func process(
        _ item: MediaItem,
        operation: ProcessingOperation,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult
}

/// Сам ничего не кодирует: достаёт оригинал и отдаёт его тому воркеру,
/// который занимается этой операцией.
struct MediaItemProcessor: ItemProcessing {
    private let library: any MediaLibrary
    private let compression: any CompressionPerforming
    private let conversion: any ConversionPerforming
    private let audio: any AudioExtractionPerforming

    init(
        library: any MediaLibrary,
        compression: any CompressionPerforming = CompressionWorker(),
        conversion: any ConversionPerforming = ConversionWorker(),
        audio: any AudioExtractionPerforming = AudioExtractionWorker()
    ) {
        self.library = library
        self.compression = compression
        self.conversion = conversion
        self.audio = audio
    }

    func process(
        _ item: MediaItem,
        operation: ProcessingOperation,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        let source = try await library.exportOriginal(item)
        defer { try? FileManager.default.removeItem(at: source) }

        switch operation {
        case let .compress(level):
            return try await compression.compress(item, source: source, level: level, progress: progress)
        case let .convert(format):
            return try await conversion.convert(item, source: source, format: format, progress: progress)
        case let .extractAudio(format):
            return try await audio.extractAudio(from: item, source: source, format: format, progress: progress)
        case .scan:
            // Страница обрабатывается не сама по себе, а вместе с документом:
            // сюда очередь скана не заходит.
            throw ProcessingError.unsupportedOperation("Страница собирается вместе с документом")
        }
    }
}
