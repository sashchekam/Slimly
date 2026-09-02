import Foundation
import SlimlyCore

/// Сжатие одного файла.
protocol CompressionPerforming: Sendable {
    func compress(
        _ item: MediaItem,
        source: URL,
        level: CompressionLevel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult
}

/// Сжатие не меняет тип файла: HEIC остаётся HEIC, MOV — MOV.
/// Иначе «сжать» незаметно превращалось бы в «сконвертировать».
struct CompressionWorker: CompressionPerforming {
    private let images: any ImageEncoding
    private let videos: any VideoTranscoding
    private let codecs: any VideoCodecProbing
    private let settings: any CompressionSettingsProviding
    private let results: any ProcessingResultWriting

    init(
        images: any ImageEncoding = ImageEncoder(),
        videos: any VideoTranscoding = VideoTranscoder(),
        codecs: any VideoCodecProbing = VideoCodecProbe(),
        settings: any CompressionSettingsProviding = EncodingSettings(),
        results: any ProcessingResultWriting = ProcessingResultWriter()
    ) {
        self.images = images
        self.videos = videos
        self.codecs = codecs
        self.settings = settings
        self.results = results
    }

    func compress(
        _ item: MediaItem,
        source: URL,
        level: CompressionLevel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        switch item.kind {
        case .photo:
            try await compressPhoto(item, source: source, level: level, progress: progress)
        case .video:
            try await compressVideo(item, source: source, level: level, progress: progress)
        }
    }

    private func compressPhoto(
        _ item: MediaItem,
        source: URL,
        level: CompressionLevel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        let format = ImageFormat.matching(fileExtension: source.pathExtension)

        return try await results.write(
            named: "\(item.baseName).\(format.fileExtension)",
            for: item,
            destination: .photoLibrary
        ) { file in
            try images.write(
                source: source,
                to: file,
                settings: ImageEncodingSettings(
                    format: format,
                    quality: settings.imageQuality(level),
                    maxPixelSize: settings.imageMaxPixelSize(level)
                )
            )
            progress(1)
        }
    }

    private func compressVideo(
        _ item: MediaItem,
        source: URL,
        level: CompressionLevel,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> ProcessingResult {
        let container: VideoContainer = source.pathExtension.lowercased() == "mp4" ? .mp4 : .mov
        let codec = await codecs.codec(of: source) ?? .hevc

        return try await results.write(
            named: "\(item.baseName).\(container.fileExtension)",
            for: item,
            destination: .photoLibrary
        ) { file in
            try await videos.transcode(
                source: source,
                destination: file,
                settings: VideoTranscodeSettings(
                    container: container,
                    codec: codec,
                    shortSideLimit: settings.videoShortSide(level),
                    bitrateFactor: settings.videoBitrateFactor(level)
                ),
                progress: progress
            )
        }
    }
}
