import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision
import SlimlyCore

/// Превращение снимка страницы в страницу скана.
///
/// Три шага, каждый из которых пользователь ждёт именно от «скана», а не
/// от «фото»: найти лист в кадре, выпрямить перспективу, вычистить фон.
/// Без них PDF был бы просто пачкой снимков, сделанных под углом на столе.
enum DocumentScanner {
    /// Длинная сторона готовой страницы в пикселях.
    ///
    /// 2000 — это около 170 dpi на A4: текст читается и печатается, а
    /// страница остаётся в пределах пары сотен килобайт. Полное разрешение
    /// снимка здесь только вредит — PDF с 12-мегапиксельными страницами
    /// не открыть на телефоне.
    private static let maxPageSide: CGFloat = 2000

    /// Ниже этой доли кадра найденный «документ» — не документ, а какой-то
    /// прямоугольник на столе. Тогда честнее взять кадр целиком.
    private static let minDocumentArea = 0.15

    /// Контекст один на все страницы: он держит текстурный кэш и скомпилированные
    /// шейдеры, и создавать его на каждую страницу — платить за это заново.
    private static let context = CIContext(options: [.cacheIntermediates: false])

    static func page(at source: URL, mode: ScanMode) throws -> ScannedPage {
        // Ориентацию применяем при чтении: снимок с телефона почти всегда
        // лежит в файле боком, а Vision ищет документ в том кадре, что видит.
        guard let input = CIImage(contentsOf: source, options: [.applyOrientationProperty: true]) else {
            throw ProcessingError.unreadableSource
        }

        let page = enhance(downscaled(corrected(input)), mode: mode)

        guard
            let image = context.createCGImage(
                page,
                from: page.extent,
                format: mode.isMonochrome ? .L8 : .RGBA8,
                colorSpace: mode.isMonochrome
                    ? CGColorSpaceCreateDeviceGray()
                    : CGColorSpace(name: CGColorSpace.sRGB)
            )
        else {
            throw ProcessingError.encodingFailed("страница не отрисовалась")
        }

        // На двухцветной странице JPEG работает против себя: он растит вес
        // на резких краях букв — ровно там, где у ч/б скана всё содержание.
        if mode == .blackAndWhite {
            return .bilevel(try packed(image))
        }
        return .jpeg(try jpeg(image, quality: mode.jpegQuality))
    }

    // MARK: Границы страницы

    /// Выпрямить лист по найденным углам.
    ///
    /// Документ не найден — возвращаем кадр как есть: обрезать наугад хуже,
    /// чем оставить поля. Пользователь увидит свою страницу, просто с фоном.
    private static func corrected(_ image: CIImage) -> CIImage {
        let request = VNDetectDocumentSegmentationRequest()
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try? handler.perform([request])

        guard
            let quad = request.results?.first,
            quad.confidence > 0.5,
            quad.boundingBox.width * quad.boundingBox.height > minDocumentArea
        else {
            return image
        }

        // Vision отдаёт доли кадра и, как и CoreImage, считает от левого
        // нижнего угла — переворачивать ось не нужно, только размасштабировать.
        let extent = image.extent
        func point(_ normalized: CGPoint) -> CGPoint {
            CGPoint(
                x: extent.origin.x + normalized.x * extent.width,
                y: extent.origin.y + normalized.y * extent.height
            )
        }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = point(quad.topLeft)
        filter.topRight = point(quad.topRight)
        filter.bottomLeft = point(quad.bottomLeft)
        filter.bottomRight = point(quad.bottomRight)
        filter.crop = true

        guard let output = filter.outputImage, output.extent.width > 1, output.extent.height > 1 else {
            return image
        }
        return output
    }

    /// Уменьшаем до печатного разрешения сразу после выпрямления, а не в конце:
    /// дальше идёт чистка фона, и гонять её по 12 мегапикселям незачем.
    private static func downscaled(_ image: CIImage) -> CIImage {
        let side = max(image.extent.width, image.extent.height)
        guard side > maxPageSide else { return image }

        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = Float(maxPageSide / side)
        filter.aspectRatio = 1
        return filter.outputImage ?? image
    }

    // MARK: Чистка страницы

    /// Выровнять освещение и добить фон до белого.
    ///
    /// `CIDocumentEnhancer` делает главное — убирает тень от руки и серизну
    /// бумаги. Дальше режим решает, сколько цвета оставить.
    private static func enhance(_ image: CIImage, mode: ScanMode) -> CIImage {
        let enhancer = CIFilter.documentEnhancer()
        enhancer.inputImage = image
        enhancer.amount = 1
        let cleaned = enhancer.outputImage ?? image

        switch mode {
        case .color:
            return cleaned

        case .grayscale:
            return desaturated(cleaned, contrast: 1.1)

        case .blackAndWhite:
            // Порог считаем по самому снимку: у страницы под лампой и
            // страницы у окна разная «белизна», и фиксированное число
            // одну из них обязательно съест.
            let threshold = CIFilter.colorThresholdOtsu()
            threshold.inputImage = desaturated(cleaned, contrast: 1)
            return threshold.outputImage ?? cleaned
        }
    }

    private static func desaturated(_ image: CIImage, contrast: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 0
        filter.contrast = contrast
        return filter.outputImage ?? image
    }

    // MARK: Запись

    /// Упаковать двухцветную страницу по биту на пиксель.
    ///
    /// Порог уже наложен фильтром, здесь остаётся только выбросить семь
    /// лишних бит из каждого байта: страница ужимается восьмикратно ещё
    /// до того, как PDF дожмёт её Flate.
    private static func packed(_ image: CGImage) throws -> ScannedPage.Bitmap {
        let width = image.width
        let height = image.height

        var gray = [UInt8](repeating: 0, count: width * height)
        guard
            let canvas = gray.withUnsafeMutableBytes({ buffer in
                CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width,
                    space: CGColorSpaceCreateDeviceGray(),
                    bitmapInfo: CGImageAlphaInfo.none.rawValue
                )
            })
        else {
            throw ProcessingError.encodingFailed("страница не отрисовалась")
        }
        canvas.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let rowBytes = (width + 7) / 8
        var bits = [UInt8](repeating: 0, count: rowBytes * height)
        for y in 0 ..< height {
            let row = y * rowBytes
            let line = y * width
            for x in 0 ..< width where gray[line + x] >= 128 {
                bits[row + x / 8] |= UInt8(0x80 >> (x % 8))
            }
        }

        return ScannedPage.Bitmap(
            width: width,
            height: height,
            rowBytes: rowBytes,
            bits: Data(bits)
        )
    }

    private static func jpeg(_ image: CGImage, quality: Double) throws -> Data {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            throw ProcessingError.encodingFailed("JPEG")
        }

        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.encodingFailed("JPEG")
        }
        return data as Data
    }
}

private extension ScanMode {
    /// В сером и ч/б цвета нет вовсе — страницу пишем одним каналом вместо
    /// трёх, и это само по себе втрое меньше данных до всякого JPEG.
    var isMonochrome: Bool { self != .color }

    /// Качество полутоновой страницы. Двухцветная в JPEG не попадает вовсе,
    /// поэтому её здесь нет.
    var jpegQuality: Double {
        switch self {
        case .color: 0.72
        case .grayscale, .blackAndWhite: 0.7
        }
    }
}
