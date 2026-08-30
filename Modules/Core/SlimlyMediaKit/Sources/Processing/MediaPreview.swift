import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Кадр из готового файла.
///
/// Нужен там, где сравнивают «до» и «после»: оригинал отдаёт медиатека,
/// а результат ещё нигде не ассет — он просто файл на диске.
public enum MediaPreview {
    private static let videoExtensions: Set<String> = ["mov", "mp4", "m4v"]

    /// JPEG-данные превью или `nil`, если кадр достать не удалось.
    public static func image(at url: URL, maxPixel: Int) async -> Data? {
        if videoExtensions.contains(url.pathExtension.lowercased()) {
            return await videoFrame(at: url, maxPixel: maxPixel)
        }
        return imageFrame(at: url, maxPixel: maxPixel)
    }

    private static func imageFrame(at url: URL, maxPixel: Int) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return jpeg(from: image)
    }

    private static func videoFrame(at url: URL, maxPixel: Int) async -> Data? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixel, height: maxPixel)

        // Первый кадр иногда чёрный — берём на секунде, если ролик длиннее.
        let duration = (try? await AVURLAsset(url: url).load(.duration).seconds) ?? 0
        let time = CMTime(seconds: duration > 2 ? 1 : 0, preferredTimescale: 600)

        guard let image = try? await generator.image(at: time).image else { return nil }
        return jpeg(from: image)
    }

    private static func jpeg(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else { return nil }

        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
