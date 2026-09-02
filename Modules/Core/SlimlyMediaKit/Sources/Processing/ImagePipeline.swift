import CoreGraphics
import Foundation
import ImageIO
import SlimlyCore
import UniformTypeIdentifiers

/// Перекодирование изображений через ImageIO.
///
/// Без UIKit намеренно: `UIImage` пришлось бы разворачивать в битмап целиком,
/// а ImageIO читает, уменьшает и пишет одним проходом и по дороге сохраняет
/// EXIF — дату съёмки и геометку, терять которые при сжатии нельзя.
enum ImagePipeline {
    struct Settings {
        let format: ImageFormat
        /// 0…1. У PNG не используется — он без потерь.
        let quality: Double
        /// Ограничение длинной стороны в пикселях. `nil` — размер не трогаем.
        let maxPixelSize: Int?
    }

    static func write(source: URL, to destination: URL, settings: Settings) throws {
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil) else {
            throw ProcessingError.unreadableSource
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] ?? [:]
        let width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        let longestSide = max(width, height)

        // Через «эскиз» идём всегда, даже когда уменьшать нечего: только он
        // умеет применить поворот из EXIF сам, и кадр не приезжает боком.
        let limit = min(settings.maxPixelSize ?? Int.max, longestSide > 0 ? longestSide : Int.max)
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: limit == Int.max ? 4096 : limit,
        ]

        guard
            let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions as CFDictionary)
                ?? CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            throw ProcessingError.unreadableSource
        }

        guard
            let imageDestination = CGImageDestinationCreateWithURL(
                destination as CFURL,
                settings.format.utType.identifier as CFString,
                1,
                nil
            )
        else {
            throw ProcessingError.unsupportedFormat(settings.format.displayName)
        }

        CGImageDestinationAddImage(
            imageDestination,
            image,
            outputProperties(from: properties, settings: settings) as CFDictionary
        )

        guard CGImageDestinationFinalize(imageDestination) else {
            throw ProcessingError.encodingFailed(settings.format.displayName)
        }
    }

    /// Метаданные переносим целиком, а ориентацию сбрасываем: кадр уже
    /// развёрнут, и второй поворот положил бы его на бок.
    private static func outputProperties(
        from source: [CFString: Any],
        settings: Settings
    ) -> [CFString: Any] {
        var properties = source
        properties[kCGImagePropertyOrientation] = 1
        properties.removeValue(forKey: kCGImagePropertyPixelWidth)
        properties.removeValue(forKey: kCGImagePropertyPixelHeight)

        if settings.format.isLossy {
            properties[kCGImageDestinationLossyCompressionQuality] = settings.quality
        }

        if var tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            tiff[kCGImagePropertyTIFFOrientation] = 1
            properties[kCGImagePropertyTIFFDictionary] = tiff
        }
        return properties
    }
}

extension ImageFormat {
    var utType: UTType {
        switch self {
        case .jpeg: .jpeg
        case .heic: .heic
        case .png: .png
        }
    }

    /// Формат исходника по расширению файла — им же и сохраняем при сжатии:
    /// сжатие меняет вес, а не тип файла.
    static func matching(fileExtension: String) -> ImageFormat {
        switch fileExtension.lowercased() {
        case "png": .png
        case "heic", "heif": .heic
        default: .jpeg
        }
    }
}
