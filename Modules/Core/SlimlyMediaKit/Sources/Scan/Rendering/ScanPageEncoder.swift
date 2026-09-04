import CoreImage
import SlimlyCore

/// Чистая картинка страницы → страница в том виде, в каком она ляжет в PDF.
protocol ScanPageEncoding: Sendable {
    func page(from image: CIImage, mode: ScanMode) throws -> ScannedPage
}

struct ScanPageEncoder: ScanPageEncoding {
    private let rasterizer: any PageRasterizing
    private let binarizer: any PageBinarizing
    private let jpeg: any JPEGEncoding

    init(
        rasterizer: any PageRasterizing = PageRasterizer(),
        binarizer: any PageBinarizing = SauvolaBinarizer(),
        jpeg: any JPEGEncoding = JPEGEncoder()
    ) {
        self.rasterizer = rasterizer
        self.binarizer = binarizer
        self.jpeg = jpeg
    }

    /// На двухцветной странице JPEG работает против себя: он растит вес
    /// на резких краях букв — ровно там, где у ч/б скана всё содержание.
    func page(from image: CIImage, mode: ScanMode) throws -> ScannedPage {
        if mode == .blackAndWhite {
            return .bilevel(binarizer.bitmap(from: try rasterizer.samples(from: image)))
        }

        let raster = try rasterizer.image(from: image, isMonochrome: mode.isMonochrome)
        guard let data = jpeg.data(from: raster, quality: mode.jpegQuality) else {
            throw ProcessingError.encodingFailed("JPEG")
        }
        return .jpeg(data)
    }
}
