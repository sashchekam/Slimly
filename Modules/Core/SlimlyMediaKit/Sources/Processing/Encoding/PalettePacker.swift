import CoreGraphics
import Foundation

/// Пережатие кадра в PNG с палитрой.
protocol PalettePacking: Sendable {
    /// - Parameter colors: длина палитры, 2…256.
    /// - Returns: `nil`, если кадр не развернулся в битмап или поток
    ///   не упаковался.
    func pack(_ image: CGImage, colors: Int) -> Data?
}

/// У PNG нет качества: формат без потерь, и `kCGImageDestinationLossyCompressionQuality`
/// на него не действует. Единственное, чем в нём можно управлять весом, —
/// длина палитры. Индекс занимает байт вместо трёх-четырёх, а повторяющиеся
/// индексы deflate жмёт куда лучше, чем шум truecolor.
struct PalettePacker: PalettePacking {
    private let quantizer: any ColorQuantizing
    private let writer: IndexedPNGWriter

    init(
        quantizer: any ColorQuantizing = MedianCutQuantizer(),
        writer: IndexedPNGWriter = IndexedPNGWriter()
    ) {
        self.quantizer = quantizer
        self.writer = writer
    }

    func pack(_ image: CGImage, colors: Int) -> Data? {
        guard let raster = RGBARaster(image) else { return nil }
        return writer.data(from: quantizer.indexed(raster, colors: colors))
    }
}
