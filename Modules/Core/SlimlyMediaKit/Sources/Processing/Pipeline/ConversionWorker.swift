import Foundation
import SlimlyCore

/// Смена формата одного файла.
protocol ConversionPerforming: Sendable {
    func convert(
        _ item: MediaItem,
        source: URL,
        format: MediaFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult
}

struct ConversionWorker: ConversionPerforming {
    /// Смена формата не должна портить кадр: качество высокое,
    /// размер не трогаем.
    private static let imageQuality = 0.9

    private let images: any ImageEncoding
    private let videos: any VideoTranscoding
    private let results: any ProcessingResultWriting

    init(
        images: any ImageEncoding = ImageEncoder(),
        videos: any VideoTranscoding = VideoTranscoder(),
        results: any ProcessingResultWriting = ProcessingResultWriter()
    ) {
        self.images = images
        self.videos = videos
        self.results = results
    }

    func convert(
        _ item: MediaItem,
        source: URL,
        format: MediaFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        switch format.target {
        case let .image(target):
            guard item.kind == .photo else {
                throw ProcessingError.unsupportedOperation(
                    L10n.Failure.videoTarget(target.displayName)
                )
            }
            return try await convertImage(item, source: source, target: target, progress: progress)

        case let .video(container, codec):
            guard item.kind == .video else {
                throw ProcessingError.unsupportedOperation(
                    L10n.Failure.photoTarget(container.displayName)
                )
            }
            return try await convertVideo(
                item,
                source: source,
                settings: VideoTranscodeSettings(
                    container: container,
                    codec: codec,
                    shortSideLimit: nil,
                    // HEVC при том же качестве требует меньше битрейта —
                    // ровно на столько, сколько обещает оценка формата.
                    bitrateFactor: format.ratio
                ),
                progress: progress
            )

        case .audio, .document:
            throw ProcessingError.unsupportedOperation(
                L10n.Failure.conversionFormat(format.id)
            )
        }
    }

    private func convertImage(
        _ item: MediaItem,
        source: URL,
        target: ImageFormat,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        try await results.write(
            named: "\(item.baseName).\(target.fileExtension)",
            for: item,
            destination: .photoLibrary
        ) { file in
            try images.write(
                source: source,
                to: file,
                settings: ImageEncodingSettings(
                    format: target,
                    quality: Self.imageQuality,
                    maxPixelSize: nil
                )
            )
            progress(1)
        }
    }

    private func convertVideo(
        _ item: MediaItem,
        source: URL,
        settings: VideoTranscodeSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        try await results.write(
            named: "\(item.baseName).\(settings.container.fileExtension)",
            for: item,
            destination: .photoLibrary
        ) { file in
            try await videos.transcode(
                source: source,
                destination: file,
                settings: settings,
                progress: progress
            )
        }
    }
}
