import CoreGraphics
import Foundation
import ImageIO

/// Кадр вместе с метаданными файла, из которого он прочитан.
struct DecodedImage {
    let image: CGImage
    let properties: [CFString: Any]
}

/// Чтение исходного изображения с уменьшением по дороге.
protocol ImageSourceReading: Sendable {
    /// - Parameter maxPixelSize: ограничение длинной стороны в пикселях.
    ///   `nil` — размер не трогаем.
    func read(at url: URL, maxPixelSize: Int?) throws -> DecodedImage
}

/// Чтение через ImageIO.
///
/// Без UIKit намеренно: `UIImage` пришлось бы разворачивать в битмап целиком,
/// а ImageIO читает и уменьшает одним проходом.
struct ImageSourceReader: ImageSourceReading {
    func read(at url: URL, maxPixelSize: Int?) throws -> DecodedImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw ProcessingError.unreadableSource
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        let longestSide = max(width, height)

        // Через «эскиз» идём всегда, даже когда уменьшать нечего: только он
        // умеет применить поворот из EXIF сам, и кадр не приезжает боком.
        let limit = min(maxPixelSize ?? Int.max, longestSide > 0 ? longestSide : Int.max)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: limit == Int.max ? 4096 : limit,
        ]

        guard
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
                ?? CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw ProcessingError.unreadableSource
        }

        return DecodedImage(image: image, properties: properties)
    }
}
