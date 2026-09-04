import CoreGraphics
import CoreImage.CIFilterBuiltins
import Foundation
import SlimlyCore

/// Достать страницу из снимка: прочитать кадр, выпрямить лист, вернуть ему
/// истинные пропорции и привести к рабочему разрешению.
///
/// Одна работа — «где на снимке страница, какой она формы и какого размера».
/// Порознь шаги не имеют смысла: выпрямлять нечего, пока кадр не прочитан,
/// пропорции считаются по тем же углам, что и выпрямление, а масштаб — уже
/// по исправленным пропорциям.
protocol PageFraming: Sendable {
    func image(at source: URL) throws -> CIImage
    /// - Parameter quad: границы листа, выбранные до обработки. `nil` —
    ///   их никто не задавал, и лист ищем сами.
    func page(from image: CIImage, quad: DocumentQuad?, resolution: PageResolution) -> CIImage
}

struct PageFramer: PageFraming {
    /// Насколько преобразование должно разойтись с тождественным, чтобы
    /// пересчёт имел смысл. Прогон через фильтр ради процента размера —
    /// только лишняя интерполяция.
    private static let tolerance: CGFloat = 0.005

    private let aspects: any PageAspectEstimating

    init(aspects: any PageAspectEstimating = PageAspectEstimator()) {
        self.aspects = aspects
    }

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
    func page(from image: CIImage, quad: DocumentQuad?, resolution: PageResolution) -> CIImage {
        guard let quad = quad ?? DocumentQuad.detected(in: image) else {
            return resized(image, to: resolution, aspect: 1)
        }

        let frame = image.extent.size
        let straightened = corrected(image, quad: quad)
        return resized(
            straightened,
            to: resolution,
            aspect: correction(for: straightened, quad: quad, frame: frame)
        )
    }

    // MARK: Ракурс

    private func corrected(_ image: CIImage, quad: DocumentQuad) -> CIImage {
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

    /// Во сколько раз растянуть выпрямленный лист по ширине, чтобы он стал
    /// той формы, какой лежал на столе.
    ///
    /// `CIPerspectiveCorrection` снимает наклон, но размер готовой картинки
    /// берёт по длинам сторон четырёхугольника как они есть — а дальний край
    /// листа в кадре короче ближнего. Ошибка доходит до четверти ширины
    /// и на глаз читается как «буквы растянуло».
    private func correction(for image: CIImage, quad: DocumentQuad, frame: CGSize) -> CGFloat {
        guard
            let wanted = aspects.ratio(of: quad, in: frame),
            image.extent.height > 0
        else {
            return 1
        }
        let actual = image.extent.width / image.extent.height
        guard actual > 0 else { return 1 }
        return wanted / actual
    }

    // MARK: Размер

    /// Ланцош, а не билинейная интерполяция: на уменьшении он единственный
    /// сохраняет тонкие штрихи букв — билинейная усредняет их с бумагой,
    /// и строчка расплывается в серую полосу.
    private func resized(_ image: CIImage, to resolution: PageResolution, aspect: CGFloat) -> CIImage {
        // Фильтр умножает ширину на `scale · aspectRatio`, а высоту — только
        // на `scale`: длинную сторону считаем уже по исправленной форме.
        let side = max(image.extent.width * aspect, image.extent.height)
        guard side > 1 else { return image }

        // Растягиваем только в разрешённых пределах: новых букв интерполяция
        // не рисует, а вес страницы растит честно.
        let scale = min(resolution.pageSide / side, resolution.maxUpscale)
        guard abs(scale - 1) > Self.tolerance || abs(aspect - 1) > Self.tolerance else { return image }

        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = Float(scale)
        filter.aspectRatio = Float(aspect)
        return filter.outputImage ?? image
    }
}
