import Foundation
import SlimlyCore

/// Извлечение звука из одного файла.
protocol AudioExtractionPerforming: Sendable {
    func extractAudio(
        from item: MediaItem,
        source: URL,
        format: MediaFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult
}

struct AudioExtractionWorker: AudioExtractionPerforming {
    private let audio: any AudioExtracting
    private let results: any ProcessingResultWriting

    init(
        audio: any AudioExtracting = AudioExtractor(),
        results: any ProcessingResultWriting = ProcessingResultWriter()
    ) {
        self.audio = audio
        self.results = results
    }

    /// Дорожка ложится в «Файлы»: звуку в медиатеке места нет.
    func extractAudio(
        from item: MediaItem,
        source: URL,
        format: MediaFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        guard case let .audio(target) = format.target, item.kind == .video else {
            throw ProcessingError.unsupportedOperation(
                L10n.Failure.audioFromPhoto
            )
        }

        return try await results.write(
            named: "\(item.baseName).\(target.fileExtension)",
            for: item,
            destination: .files
        ) { file in
            try await audio.extract(
                source: source,
                destination: file,
                format: target,
                progress: progress
            )
        }
    }
}
