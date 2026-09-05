import CoreGraphics
import CoreImage
import Foundation

/// Граф фильтров CoreImage в настоящие пиксели.
protocol PageRasterizing: Sendable {
    /// Растр под запись в JPEG.
    func image(from page: CIImage, isMonochrome: Bool) throws -> CGImage
    /// Байт на пиксель — с этим работает порог.
    func samples(from page: CIImage) throws -> GrayscaleBuffer
}

struct PageRasterizer: PageRasterizing {
    /// Контекст один на все страницы: он держит текстурный кэш и
    /// скомпилированные шейдеры, и создавать его на каждую страницу —
    /// платить за это заново.
    private let context: CIContext

    init() {
        context = CIContext(
            options: [
                // Промежуточные результаты не переиспользуются: каждая
                // страница проходит цепочку ровно один раз, а весит она
                // теперь десятки мегапикселей.
                .cacheIntermediates: false,
                // Уменьшение в несколько проходов вместо одного: тонкие
                // штрихи букв не проваливаются между пикселями.
                .highQualityDownsample: true,
            ]
        )
    }

    func image(from page: CIImage, isMonochrome: Bool) throws -> CGImage {
        let bounds = page.extent.integral
        guard
            let image = context.createCGImage(
                page,
                from: bounds,
                format: isMonochrome ? .L8 : .RGBA8,
                colorSpace: isMonochrome
                    ? CGColorSpaceCreateDeviceGray()
                    : CGColorSpace(name: CGColorSpace.sRGB)
            )
        else {
            throw ProcessingError.encodingFailed(L10n.Reason.pageNotRendered)
        }
        return image
    }

    func samples(from page: CIImage) throws -> GrayscaleBuffer {
        let bounds = page.extent.integral
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        guard width > 0, height > 0 else {
            throw ProcessingError.encodingFailed(L10n.Reason.pageNotRendered)
        }

        var samples = [UInt8](repeating: 0, count: width * height)
        samples.withUnsafeMutableBytes { buffer in
            guard let start = buffer.baseAddress else { return }
            context.render(
                page,
                toBitmap: start,
                rowBytes: width,
                bounds: bounds,
                format: .L8,
                colorSpace: CGColorSpaceCreateDeviceGray()
            )
        }
        return GrayscaleBuffer(width: width, height: height, samples: samples)
    }
}
