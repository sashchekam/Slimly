import CoreGraphics
import CoreImage.CIFilterBuiltins
import Foundation
import SlimlyCore

/// Достать страницу из снимка: прочитать кадр, выпрямить лист, привести
/// его к рабочему разрешению.
///
/// Три шага одной работы — «где на снимке страница и какого она размера».
/// Порознь ни один из них не имеет смысла: выпрямлять нечего, пока кадр
/// не прочитан, а масштаб считается от уже выпрямленного листа.
protocol PageFraming: Sendable {
    func image(at source: URL) throws -> CIImage
    /// - Parameter quad: границы листа, выбранные до обработки. `nil` —
    ///   их никто не задавал, и лист ищем сами.
    func corrected(_ image: CIImage, quad: DocumentQuad?) -> CIImage
    func resized(_ image: CIImage, to resolution: PageResolution) -> CIImage
}

struct PageFramer: PageFraming {
    /// Насколько масштаб должен разойтись с единицей, чтобы пересчёт имел
    /// смысл. Прогон через фильтр ради процента размера — только лишняя
    /// интерполяция.
    private static let tolerance: CGFloat = 0.01

    func image(at source: URL) throws -> CIImage {
        // Ориентацию применяем при чтении: снимок с телефона почти всегда
        // лежит в файле боком, а лист ищется в том кадре, что видит человек.
        guard let image = CIImage(contentsOf: source, options: [.applyOrientationProperty: true]) else {
            throw ProcessingError.unreadableSource
        }
        return image
    }

    /// Границы приходят с экрана правки, а если их там не задали — ищем сами.
    /// Не нашли и сами — возвращаем кадр как есть: обрезать наугад хуже, чем
    /// оставить поля. Пользователь увидит свою страницу, просто с фоном.
    func corrected(_ image: CIImage, quad: DocumentQuad?) -> CIImage {
        guard let quad = quad ?? DocumentQuad.detected(in: image) else { return image }

        // Доли считаются от левого верхнего угла, а CoreImage — от левого
        // нижнего: переворачиваем ось на входе в фильтр.
        let extent = image.extent
        func point(_ normalized: CGPoint) -> CGPoint {
            CGPoint(
                x: extent.origin.x + normalized.x * extent.width,
                y: extent.origin.y + (1 - normalized.y) * extent.height
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

    /// Ланцош, а не билинейная интерполяция: на уменьшении он единственный
    /// сохраняет тонкие штрихи букв — билинейная усредняет их с бумагой,
    /// и строчка расплывается в серую полосу.
    func resized(_ image: CIImage, to resolution: PageResolution) -> CIImage {
        let side = max(image.extent.width, image.extent.height)
        guard side > 1 else { return image }

        // Растягиваем только в разрешённых пределах: новых букв интерполяция
        // не рисует, а вес страницы растит честно.
        let scale = min(resolution.pageSide / side, resolution.maxUpscale)
        guard abs(scale - 1) > Self.tolerance else { return image }

        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = Float(scale)
        filter.aspectRatio = 1
        return filter.outputImage ?? image
    }
}
