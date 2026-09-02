import Foundation
import SlimlyCore

struct ImageEncodingSettings {
    let format: ImageFormat
    /// 0…1. У PNG не используется — он без потерь.
    let quality: Double
    /// Ограничение длинной стороны в пикселях. `nil` — размер не трогаем.
    let maxPixelSize: Int?
}

/// Перекодирование изображения из файла в файл.
protocol ImageEncoding: Sendable {
    func write(source: URL, to destination: URL, settings: ImageEncodingSettings) throws
}

/// Три шага поверх ImageIO: прочитать кадр, собрать метаданные, записать.
///
/// EXIF переносится по дороге — дату съёмки и геометку при сжатии терять
/// нельзя, а собирает их отдельный воркер, потому что правило «какие
/// метаданные оставить» меняется чаще, чем сама запись.
struct ImageEncoder: ImageEncoding {
    private let reader: any ImageSourceReading
    private let metadata: any ImageOutputPropertiesComposing
    private let writer: any ImageDestinationWriting

    init(
        reader: any ImageSourceReading = ImageSourceReader(),
        metadata: any ImageOutputPropertiesComposing = ImageOutputProperties(),
        writer: any ImageDestinationWriting = ImageDestinationWriter()
    ) {
        self.reader = reader
        self.metadata = metadata
        self.writer = writer
    }

    func write(source: URL, to destination: URL, settings: ImageEncodingSettings) throws {
        let decoded = try reader.read(at: source, maxPixelSize: settings.maxPixelSize)

        try writer.write(
            decoded.image,
            to: destination,
            format: settings.format,
            properties: metadata.properties(from: decoded.properties, settings: settings)
        )
    }
}
