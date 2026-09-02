import Foundation
import SlimlyCore

/// Кадр из готового файла.
///
/// Нужен на экране просмотра результата: оригинал отдаёт медиатека,
/// а результат ещё нигде не ассет — он просто файл на диске. Документ сюда
/// не попадает: PDF показывает системный просмотрщик целиком.
public struct SystemMediaPreviewRenderer: MediaPreviewRenderer {
    private static let videoExtensions: Set<String> = ["mov", "mp4", "m4v"]

    private let images: any ImageFrameExtracting
    private let videos: any VideoFrameExtracting

    public init() {
        self.init(images: ImageFrameExtractor(), videos: VideoFrameExtractor())
    }

    init(images: any ImageFrameExtracting, videos: any VideoFrameExtracting) {
        self.images = images
        self.videos = videos
    }

    public func preview(at url: URL, maxPixel: Int) async -> Data? {
        if Self.videoExtensions.contains(url.pathExtension.lowercased()) {
            return await videos.frame(at: url, maxPixel: maxPixel)
        }
        return images.frame(at: url, maxPixel: maxPixel)
    }
}
