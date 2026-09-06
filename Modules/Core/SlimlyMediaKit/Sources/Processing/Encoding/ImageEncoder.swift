import CoreGraphics
import Foundation
import SlimlyCore

struct ImageEncodingSettings {
    let format: ImageFormat
    /// 0…1. У PNG не используется — он без потерь.
    let quality: Double
    /// Ограничение длинной стороны в пикселях. `nil` — размер не трогаем.
    let maxPixelSize: Int?
    /// Длина палитры для PNG. `nil` — палитру не собираем и пишем truecolor:
    /// приближение цветов уместно при сжатии, но не при смене формата,
    /// где от PNG ждут точной копии кадра.
    var paletteColors: Int?
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
    private let palette: any PalettePacking

    init(
        reader: any ImageSourceReading = ImageSourceReader(),
        metadata: any ImageOutputPropertiesComposing = ImageOutputProperties(),
        writer: any ImageDestinationWriting = ImageDestinationWriter(),
        palette: any PalettePacking = PalettePacker()
    ) {
        self.reader = reader
        self.metadata = metadata
        self.writer = writer
        self.palette = palette
    }

    func write(source: URL, to destination: URL, settings: ImageEncodingSettings) throws {
        let decoded = try reader.read(at: source, maxPixelSize: settings.maxPixelSize)

        try writer.write(
            decoded.image,
            to: destination,
            format: settings.format,
            properties: metadata.properties(from: decoded.properties, settings: settings)
        )

        try packPalette(decoded.image, at: destination, settings: settings)
    }

    /// Палитра выигрывает не всегда: на фотографии индексы приближённых
    /// цветов весят больше честного truecolor. Поэтому она заменяет запись
    /// ImageIO только тогда, когда действительно легче, а не «потому что PNG».
    private func packPalette(
        _ image: CGImage,
        at destination: URL,
        settings: ImageEncodingSettings
    ) throws {
        guard
            settings.format == .png,
            let colors = settings.paletteColors,
            let packed = palette.pack(image, colors: colors),
            packed.count < destination.byteCount
        else { return }

        try packed.write(to: destination, options: .atomic)
    }
}
