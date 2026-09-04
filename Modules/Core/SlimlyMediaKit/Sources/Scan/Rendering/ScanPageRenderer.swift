import Foundation
import SlimlyCore

/// Снимок страницы → страница скана, готовая лечь в PDF.
protocol ScanPageRendering: Sendable {
    /// - Parameter quad: границы листа, выбранные до обработки. `nil` —
    ///   их никто не задавал, и лист ищем сами.
    func page(at source: URL, mode: ScanMode, quad: DocumentQuad?) throws -> ScannedPage
}

/// Сборка: сам ничего не считает, а раздаёт работу трём воркерам —
/// геометрии страницы, её чистке и кодировщику.
struct ScanPageRenderer: ScanPageRendering {
    private let frames: any PageFraming
    private let cleaner: any PageCleaning
    private let pages: any ScanPageEncoding

    init(
        frames: any PageFraming = PageFramer(),
        cleaner: any PageCleaning = PageCleaner(),
        pages: any ScanPageEncoding = ScanPageEncoder()
    ) {
        self.frames = frames
        self.cleaner = cleaner
        self.pages = pages
    }

    /// Порядок шагов не переставляется.
    ///
    /// Перспективу правим по полному кадру — у выпрямления тем больше
    /// материала, чем больше пикселей. Размер приводим сразу после неё,
    /// до чистки: так `CIDocumentEnhancer` видит ту же страницу, что уедет
    /// в PDF, и его локальные окна попадают по буквам, а не по размеру
    /// исходного снимка.
    func page(at source: URL, mode: ScanMode, quad: DocumentQuad?) throws -> ScannedPage {
        let frame = try frames.image(at: source)
        let straightened = frames.corrected(frame, quad: quad)
        let scaled = frames.resized(straightened, to: mode.resolution)

        return try pages.page(from: cleaner.cleaned(scaled, mode: mode), mode: mode)
    }
}
