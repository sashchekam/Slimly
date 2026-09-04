import CoreGraphics
import CoreImage.CIFilterBuiltins
import Foundation
import SlimlyCore

/// Привести страницу к тому виду, какого от скана ждут: ровный белый фон,
/// резкий край буквы и плотные чернила.
protocol PageCleaning: Sendable {
    func cleaned(_ image: CIImage, mode: ScanMode) -> CIImage
}

/// Четыре шага. `CIDocumentEnhancer` убирает тень от руки и серизну бумаги,
/// режим решает, сколько цвета оставить, маска нерезкости возвращает краю
/// штриха контраст, а кривая плотности переводит серую букву в чёрную.
///
/// Без последнего шага страница остаётся фотографией текста: фон белый,
/// а буквы серые и мягкие. Именно это отличает снимок от скана — не фон,
/// а то, сколько в букве чёрного.
struct PageCleaner: PageCleaning {
    /// Лёгкий подъём контраста для серой страницы: цвета в ней уже нет,
    /// и разводить чернила с бумагой приходится одной яркостью.
    private static let grayscaleContrast: Float = 1.1

    /// Радиус резкости привязан к размеру страницы, а не задан числом:
    /// на трёхстах dpi штрих буквы шире, чем на ста пятидесяти, и один
    /// и тот же радиус в пикселях означал бы там и там разное.
    private static let sharpenRadius: CGFloat = 1 / 3000
    /// Ниже этого радиуса фильтр работает уже по шуму матрицы, а не по буквам.
    private static let minimumRadius: CGFloat = 0.8
    /// Сила подъёма. Больше — и вокруг букв появляется белый ореол, который
    /// на печати виден отчётливее, чем сама прибавка резкости.
    private static let sharpenIntensity: Float = 0.6

    /// Ступеней в таблице кривой. Шестидесяти четырёх хватает: кривая
    /// пологая везде, кроме перехода от бумаги к чернилам, а между
    /// ступенями CoreImage доводит значения сам.
    private static let curveSteps = 64

    func cleaned(_ image: CIImage, mode: ScanMode) -> CIImage {
        // Свёртки расширяют кадр на свой радиус — страница должна остаться
        // ровно той, какой её отдала геометрия.
        let bounds = image.extent

        let page = sharpened(enhanced(image, mode: mode))
        guard let curve = mode.inkCurve else { return page.cropped(to: bounds) }

        return inked(page, with: curve).cropped(to: bounds)
    }

    // MARK: Фон и цвет

    private func enhanced(_ image: CIImage, mode: ScanMode) -> CIImage {
        let enhancer = CIFilter.documentEnhancer()
        enhancer.inputImage = image
        enhancer.amount = 1
        let cleaned = enhancer.outputImage ?? image

        switch mode {
        case .color:
            return cleaned
        case .grayscale:
            return desaturated(cleaned, contrast: Self.grayscaleContrast)
        case .blackAndWhite:
            return desaturated(cleaned, contrast: 1)
        }
    }

    private func desaturated(_ image: CIImage, contrast: Float) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 0
        filter.contrast = contrast
        return filter.outputImage ?? image
    }

    // MARK: Резкость

    /// Страницу размывает не один шаг, а все сразу: объектив телефона, JPEG
    /// камеры, выпрямление перспективы и пересчёт размера. Каждый съедает
    /// по чуть-чуть, а вместе они и дают мягкий край буквы.
    private func sharpened(_ image: CIImage) -> CIImage {
        let side = max(image.extent.width, image.extent.height)
        guard side > 1 else { return image }

        let filter = CIFilter.unsharpMask()
        filter.inputImage = image
        filter.radius = Float(max(Self.minimumRadius, side * Self.sharpenRadius))
        filter.intensity = Self.sharpenIntensity
        return filter.outputImage ?? image
    }

    // MARK: Плотность чернил

    /// Кривую задаём таблицей, а не пятью точками `CIToneCurve`: сплайн
    /// по точкам выгибается между ними и на крутом участке высветляет
    /// ровно тот полутон, ради которого всё и затевалось.
    ///
    /// Таблица объявлена в sRGB — числа в ней означают то же, что видит
    /// глаз. Само пространство CoreImage линейное, и без этой пометки
    /// пороги бумаги и чернил указывали бы совсем в другие места шкалы.
    private func inked(_ image: CIImage, with curve: InkCurve) -> CIImage {
        let filter = CIFilter.colorCurves()
        filter.inputImage = image
        filter.curvesData = table(for: curve)
        filter.curvesDomain = CIVector(x: 0, y: 1)
        filter.colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        return filter.outputImage ?? image
    }

    private func table(for curve: InkCurve) -> Data {
        var values: [Float] = []
        values.reserveCapacity(Self.curveSteps * 3)

        for step in 0 ..< Self.curveSteps {
            let value = Float(step) / Float(Self.curveSteps - 1)
            let density = min(max((curve.paper - value) / (curve.paper - curve.ink), 0), 1)
            let mapped = 1 - pow(density, curve.gamma)
            values.append(contentsOf: [mapped, mapped, mapped])
        }

        return values.withUnsafeBufferPointer { Data(buffer: $0) }
    }
}
