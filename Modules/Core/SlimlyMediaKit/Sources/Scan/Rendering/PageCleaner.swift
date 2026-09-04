import CoreGraphics
import CoreImage.CIFilterBuiltins
import Foundation
import SlimlyCore

/// Привести страницу к тому виду, какого от скана ждут: ровный белый фон,
/// резкий край буквы и плотные чернила.
protocol PageCleaning: Sendable {
    func cleaned(_ image: CIImage, mode: ScanMode) -> CIImage
}

/// Пять шагов. `CIDocumentEnhancer` убирает тень и серизну бумаги, режим
/// решает, сколько цвета оставить, шумодав снимает зерно матрицы, маска
/// нерезкости возвращает краю штриха контраст, а кривая плотности переводит
/// серую букву в чёрную.
///
/// Без последнего шага страница остаётся фотографией текста: фон белый,
/// а буквы серые и мягкие. Именно это отличает снимок от скана — не фон,
/// а то, сколько в букве чёрного.
struct PageCleaner: PageCleaning {
    /// Сила выравнивания фона. Шкала фильтра — от нуля до двух, и половина
    /// её оставляет на странице тень от руки: на снимке с жёсткой тенью
    /// единица вдвое хуже полутора по расхождению с эталоном, а на ровно
    /// освещённом листе разницы между ними уже нет. Дороже единицы этот
    /// шаг не становится, поэтому платить за худший случай можно всегда.
    private static let enhancement: Float = 1.6

    /// Порог шумодава. Зерно матрицы само по себе почти не видно, но маска
    /// нерезкости следом поднимает его наравне с буквами — и на пустом поле
    /// появляется крупа, которой в исходнике не было.
    private static let noiseLevel: Float = 0.02
    /// Сколько резкости шумодав оставляет себе. Значение фильтра
    /// по умолчанию: он всё равно идёт перед маской нерезкости.
    private static let noiseSharpness: Float = 0.4

    /// Радиус резкости привязан к размеру страницы, а не задан числом:
    /// на четырёхстах dpi штрих буквы шире, чем на трёхстах, и один и тот же
    /// радиус в пикселях означал бы там и там разное. Доля подобрана
    /// по расхождению с эталонной страницей — это примерно ширина штриха
    /// основного текста.
    private static let sharpenRadius: CGFloat = 1 / 1750
    /// Ниже этого радиуса фильтр работает уже по шуму матрицы, а не по буквам.
    private static let minimumRadius: CGFloat = 1.2
    /// Сила подъёма. Верх шкалы: ореол вокруг буквы появляется от радиуса,
    /// а не от силы, и при радиусе в один штрих его ещё нет.
    private static let sharpenIntensity: Float = 1

    /// Ступеней в таблице кривой. Крутой участок кривой узкий, и на
    /// шестидесяти четырёх ступенях он занимает три-четыре из них —
    /// перепад бумага-чернила получается ступенчатым.
    private static let curveSteps = 128

    func cleaned(_ image: CIImage, mode: ScanMode) -> CIImage {
        // Свёртки расширяют кадр на свой радиус — страница должна остаться
        // ровно той, какой её отдала геометрия.
        let bounds = image.extent

        let page = sharpened(denoised(enhanced(image, mode: mode)))
        guard let curve = mode.inkCurve else { return page.cropped(to: bounds) }

        return inked(page, with: curve).cropped(to: bounds)
    }

    // MARK: Фон и цвет

    private func enhanced(_ image: CIImage, mode: ScanMode) -> CIImage {
        let enhancer = CIFilter.documentEnhancer()
        enhancer.inputImage = image
        enhancer.amount = Self.enhancement
        let cleaned = enhancer.outputImage ?? image

        return mode.isMonochrome ? desaturated(cleaned) : cleaned
    }

    private func desaturated(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 0
        return filter.outputImage ?? image
    }

    // MARK: Зерно

    private func denoised(_ image: CIImage) -> CIImage {
        let filter = CIFilter.noiseReduction()
        filter.inputImage = image
        filter.noiseLevel = Self.noiseLevel
        filter.sharpness = Self.noiseSharpness
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
        // Фильтр читает пиксели за краем страницы: без растяжки края
        // он берёт там прозрачность и обводит лист тёмной рамкой.
        filter.inputImage = image.clampedToExtent()
        filter.radius = Float(max(Self.minimumRadius, side * Self.sharpenRadius))
        filter.intensity = Self.sharpenIntensity
        return (filter.outputImage ?? image).cropped(to: image.extent)
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
