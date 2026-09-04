import AVFoundation
import CoreGraphics
import Foundation

/// Кадр из видеофайла.
protocol VideoFrameExtracting: Sendable {
    /// JPEG-данные превью или `nil`, если кадр достать не удалось.
    func frame(at url: URL, maxPixel: Int) async -> Data?
}

struct VideoFrameExtractor: VideoFrameExtracting {
    /// Превью показывают мелко, но рядом с оригиналом: заметная разница
    /// здесь читалась бы как испорченный результат.
    private static let quality = 0.9

    private let jpeg: any JPEGEncoding

    init(jpeg: any JPEGEncoding = JPEGEncoder()) {
        self.jpeg = jpeg
    }

    func frame(at url: URL, maxPixel: Int) async -> Data? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixel, height: maxPixel)

        // Первый кадр иногда чёрный — берём на секунде, если ролик длиннее.
        let duration = (try? await asset.load(.duration).seconds) ?? 0
        let time = CMTime(seconds: duration > 2 ? 1 : 0, preferredTimescale: 600)

        guard let image = try? await generator.image(at: time).image else { return nil }
        return jpeg.data(from: image, quality: Self.quality)
    }
}
