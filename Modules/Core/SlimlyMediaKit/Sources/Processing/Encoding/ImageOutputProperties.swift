import Foundation
import ImageIO

/// Метаданные, с которыми кадр ляжет в новый файл.
protocol ImageOutputPropertiesComposing: Sendable {
    func properties(from source: [CFString: Any], settings: ImageEncodingSettings) -> [CFString: Any]
}

struct ImageOutputProperties: ImageOutputPropertiesComposing {
    /// Метаданные переносим целиком, а ориентацию сбрасываем: кадр уже
    /// развёрнут, и второй поворот положил бы его на бок.
    func properties(from source: [CFString: Any], settings: ImageEncodingSettings) -> [CFString: Any] {
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
