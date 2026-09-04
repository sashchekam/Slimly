import Foundation
import ImageIO

/// Уменьшенный кадр из файла изображения.
protocol ImageFrameExtracting: Sendable {
    /// JPEG-данные превью или `nil`, если кадр достать не удалось.
    func frame(at url: URL, maxPixel: Int) -> Data?
}

struct ImageFrameExtractor: ImageFrameExtracting {
    /// Превью показывают мелко, но рядом с оригиналом: заметная разница
    /// здесь читалась бы как испорченный результат.
    private static let quality = 0.9

    private let jpeg: any JPEGEncoding

    init(jpeg: any JPEGEncoding = JPEGEncoder()) {
        self.jpeg = jpeg
    }

    func frame(at url: URL, maxPixel: Int) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return jpeg.data(from: image, quality: Self.quality)
    }
}
